#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

case_id="${1:?usage: run-remediation-reference.sh CVE-... REFERENCE_ID}"
reference_id="${2:?usage: run-remediation-reference.sh CVE-... REFERENCE_ID}"
reference_dir="$SCL_ROOT/cases/$case_id/remediation/$reference_id"
override="$reference_dir/docker-compose.override.yml"
test_script="$reference_dir/test.sh"
[[ -r "$override" && -x "$test_script" ]] || {
  echo "Missing remediation override or executable test under $reference_dir" >&2
  exit 1
}

experiment_id="${case_id}-remediation-${reference_id}-$(date -u +%Y%m%dT%H%M%SZ)"
run_dir="$SCL_ROOT/evidence-runs/$experiment_id"
mkdir -p "$run_dir"/{shared,requests,responses,logs,pcaps,siem,egress}
chmod 0755 "$run_dir" "$run_dir"/{requests,responses,logs,pcaps,siem,egress}
chmod 0777 "$run_dir/shared"
touch "$run_dir/shared"/{waf-normalized.jsonl,ips-normalized.jsonl,response-dlp.jsonl,egress-dlp.jsonl,internal-assets.jsonl,receiver.jsonl,runtime.jsonl,authorization.jsonl}
chmod 0666 "$run_dir/shared"/*.jsonl
ln -sfn "$run_dir" "$SCL_ROOT/evidence-runs/current"
printf '%s\n' "$case_id" >"$run_dir/CASE"
printf '%s\n' remediation >"$run_dir/MODE"
printf '%s\n' "$reference_id" >"$run_dir/REMEDIATION_REFERENCE"
printf '%s\n' "$experiment_id" >"$run_dir/EXPERIMENT_ID"

export CASE_ID="$case_id" LAB_MODE=mode-a EVIDENCE_DIR="$run_dir"
export EXPERIMENT_ID="$experiment_id" CASE_BACKEND="$(case_backend "$case_id")"
export SCL_COMPOSE_PROJECT_NAME=scl-remediation SCL_COMPOSE_EXTRA_FILE="$override"
args=(docker compose -p scl-remediation -f "$INFRA_COMPOSE" \
  -f "$SCL_ROOT/cases/$case_id/docker-compose.yml" \
  -f "$SCL_ROOT/cases/$case_id/mode-a/docker-compose.override.yml" \
  -f "$override")
profiles=()
if [[ "$case_id" != CVE-2023-46604 ]]; then profiles+=(--profile web); fi
# Remediation references exercise the server request directly. The optional
# TeamCity build agent is outside the authentication-bypass assertion and is
# intentionally not started, avoiding an unrelated mutable dependency.
if docker network inspect single-node_default >/dev/null 2>&1; then profiles+=(--profile siem); fi

cleanup_needed=yes
cleanup() {
  if [[ "$cleanup_needed" == yes ]]; then
    "${args[@]}" "${profiles[@]}" stop >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

"${args[@]}" config >"$run_dir/compose-rendered.yml"
"${args[@]}" "${profiles[@]}" up -d --build --force-recreate
ips_service=ips
[[ "$case_id" == CVE-2023-46604 ]] && ips_service=openwire-ips
ready=no
for _attempt in $(seq 1 180); do
  if "${args[@]}" logs --no-color "$ips_service" 2>/dev/null | grep -q 'Engine started'; then
    if [[ "$case_id" == CVE-2023-46604 ]]; then
      ready=yes
      break
    fi
    waf_id="$("${args[@]}" ps -q waf)"
    waf_health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$waf_id" 2>/dev/null || true)"
    if [[ "$waf_health" == healthy ]]; then
      ready=yes
      break
    fi
  fi
  sleep 1
done
[[ "$ready" == yes ]] || {
  "${args[@]}" ps -a >"$run_dir/readiness-failure-state.txt" || true
  "${args[@]}" logs --no-color --timestamps >"$run_dir/readiness-failure.log" 2>&1 || true
  echo "Remediation reference failed readiness; evidence: $run_dir" >&2
  exit 1
}

"${args[@]}" ps >"$run_dir/container-state.txt"
docker image ls --digests --no-trunc >"$run_dir/image-inventory.txt"
"$test_script"
bash "$SCL_ROOT/scripts/verify-isolation.sh" "$case_id" mode-a
sleep 10
"${args[@]}" ps >"$run_dir/container-state-after.txt" || true
"${args[@]}" logs --no-color --timestamps >"$run_dir/logs/compose.log" 2>&1 || true
docker network inspect scl_simulated_internet scl_application scl_protected_internal scl_egress \
  >"$run_dir/network-inspect.json" 2>"$run_dir/network-inspect.stderr" || true

"${args[@]}" "${profiles[@]}" stop
cleanup_needed=no
sleep 2
bash "$SCL_ROOT/scripts/export-wazuh-evidence.sh" "$run_dir" || true
printf 'Finalized at %s after remediation services stopped.\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$run_dir/FINALIZED"
(
  cd "$run_dir"
  find . -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum >SHA256SUMS.txt
  sha256sum -c SHA256SUMS.txt >/dev/null
)
chmod -R a-w "$run_dir" 2>/dev/null || true
if find "$run_dir" -writable -print -quit | grep -q .; then
  echo "Final remediation snapshot still contains writable paths" >&2
  exit 1
fi
echo "Portable remediation snapshot created: $run_dir"
