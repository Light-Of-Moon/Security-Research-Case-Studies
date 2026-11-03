#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
case_id="${1:?usage: verify-isolation.sh CVE-... mode-a|mode-b}"
mode="${2:?usage: verify-isolation.sh CVE-... mode-a|mode-b}"
run_dir="$(readlink -f "$SCL_ROOT/evidence-runs/current")"
report="$run_dir/logs/isolation.txt"
mapfile -t files < <(compose_files "$case_id" "$mode")
project="${SCL_COMPOSE_PROJECT_NAME:-scl-lab}"
args=(docker compose -p "$project")
for file in "${files[@]}"; do args+=(-f "$file"); done
[[ -z "${SCL_COMPOSE_EXTRA_FILE:-}" ]] || args+=(-f "$SCL_COMPOSE_EXTRA_FILE")
exec > >(tee "$report") 2>&1
failures=0

attacker_id="$("${args[@]}" ps -q attacker)"
target_id="$("${args[@]}" ps -q case-target)"
internal_id="$("${args[@]}" ps -q internal-assets)"
receiver_id="$("${args[@]}" ps -q external-receiver)"
for item in "$attacker_id" "$target_id" "$internal_id" "$receiver_id"; do
  [[ -n "$item" ]] || { echo "ERROR: required container ID is missing"; exit 1; }
done

echo "Probe capability checks (must succeed)"
if ! docker run --rm --network scl_simulated_internet curlimages/curl:8.12.1 \
  --version >/dev/null; then
  echo "ERROR: independent attacker-zone probe could not start"
  exit 1
fi
if ! docker run --rm --network "container:$target_id" curlimages/curl:8.12.1 --version >/dev/null; then
  echo "ERROR: independent target-network probe could not start"
  exit 1
fi
echo PASS

echo "Docker protected networks marked internal (must all be true)"
for network in scl_simulated_internet scl_ingress scl_application scl_protected_internal scl_egress scl_management; do
  internal="$(docker network inspect --format '{{.Internal}}' "$network" 2>/dev/null || true)"
  printf '%s internal=%s\n' "$network" "${internal:-missing}"
  [[ "$internal" == true ]] || failures=$((failures + 1))
done
[[ "$failures" == 0 ]] && echo PASS || echo FAIL

protected_ip="$(docker inspect --format '{{with index .NetworkSettings.Networks "scl_protected_internal"}}{{.IPAddress}}{{end}}' "$internal_id")"
[[ -n "$protected_ip" ]] || { echo "ERROR: protected service has no protected-network IP"; exit 1; }

echo "Attacker -> protected service by DNS (must fail)"
if docker run --rm --network scl_simulated_internet curlimages/curl:8.12.1 \
  --connect-timeout 3 --max-time 5 -fsS \
  http://internal-assets:8080/health; then
  echo FAIL
  failures=$((failures + 1))
else
  echo PASS
fi

echo "Attacker -> protected service by IP $protected_ip (must fail)"
if docker run --rm --network scl_simulated_internet curlimages/curl:8.12.1 \
  --connect-timeout 3 --max-time 5 -fsS \
  "http://$protected_ip:8080/health"; then
  echo FAIL
  failures=$((failures + 1))
else
  echo PASS
fi

echo "Target network namespace -> real Internet IP (must fail)"
if docker run --rm --network "container:$target_id" curlimages/curl:8.12.1 \
  --connect-timeout 3 --max-time 5 -fsS http://1.1.1.1/; then
  echo FAIL
  failures=$((failures + 1))
else
  echo PASS
fi

echo "Target network namespace -> cloud metadata IP (must fail)"
if docker run --rm --network "container:$target_id" curlimages/curl:8.12.1 \
  --connect-timeout 3 --max-time 5 -fsS http://169.254.169.254/; then
  echo FAIL
  failures=$((failures + 1))
else
  echo PASS
fi

echo "External receiver published ports (must be empty)"
published="$(docker port "$receiver_id" 2>/dev/null || true)"
if [[ -z "$published" ]]; then
  echo PASS
else
  echo "$published"
  echo FAIL
  failures=$((failures + 1))
fi

echo "Container network memberships"
docker inspect --format 'attacker={{json .NetworkSettings.Networks}}' "$attacker_id"
docker inspect --format 'target={{json .NetworkSettings.Networks}}' "$target_id"
docker inspect --format 'internal-assets={{json .NetworkSettings.Networks}}' "$internal_id"
docker inspect --format 'external-receiver={{json .NetworkSettings.Networks}}' "$receiver_id"

if [[ "$failures" -eq 0 ]]; then
  echo "ISOLATION_RESULT=PASS"
else
  echo "ISOLATION_RESULT=FAIL failures=$failures"
  exit 1
fi
