#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
case_id="${1:?usage: start-case.sh CVE-... mode-a|mode-b}"
mode="${2:?usage: start-case.sh CVE-... mode-a|mode-b}"
validate_mode "$mode"
backend="$(case_backend "$case_id")"
experiment_id="${EXPERIMENT_ID:-${case_id}-${mode}-$(date -u +%Y%m%dT%H%M%SZ)}"
run_dir="$SCL_ROOT/evidence-runs/$experiment_id"
mkdir -p "$run_dir"/{shared,requests,responses,logs,pcaps,siem,egress}
chmod 0755 "$run_dir" "$run_dir"/{requests,responses,logs,pcaps,siem,egress}
# Only the shared sensor exchange is writable by the distinct unprivileged
# UIDs used by WAF/IPS/DLP/receiver containers. Attack and diagnostic clients
# never mount this directory.
chmod 0777 "$run_dir/shared"
touch "$run_dir/shared"/{waf-normalized.jsonl,ips-normalized.jsonl,response-dlp.jsonl,egress-dlp.jsonl,internal-assets.jsonl,receiver.jsonl,runtime.jsonl,authorization.jsonl}
chmod 0666 "$run_dir/shared"/*.jsonl
if [[ -e "$SCL_ROOT/evidence-runs/current" && ! -L "$SCL_ROOT/evidence-runs/current" ]]; then
  echo "evidence-runs/current exists and is not a symlink; refusing to replace it" >&2
  exit 1
fi
ln -sfn "$run_dir" "$SCL_ROOT/evidence-runs/current"
printf '%s\n' "$case_id" > "$run_dir/CASE"
printf '%s\n' "$mode" > "$run_dir/MODE"
printf '%s\n' "$experiment_id" > "$run_dir/EXPERIMENT_ID"
export CASE_BACKEND="$backend" EXPERIMENT_ID="$experiment_id" LAB_MODE="$mode"
mapfile -t files < <(compose_files "$case_id" "$mode")
args=(docker compose -p scl-lab)
for file in "${files[@]}"; do args+=(-f "$file"); done
if [[ "$case_id" != CVE-2023-46604 ]]; then args+=(--profile web); fi
if docker network inspect single-node_default >/dev/null 2>&1; then args+=(--profile siem); fi
"${args[@]}" config > "$run_dir/compose-rendered.yml"
"${args[@]}" up -d --build --force-recreate
ips_service=ips
[[ "$case_id" == CVE-2023-46604 ]] && ips_service=openwire-ips
ready=no
for _attempt in $(seq 1 120); do
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
if [[ "$ready" != yes ]]; then
  "${args[@]}" ps -a > "$run_dir/readiness-failure-state.txt" || true
  "${args[@]}" logs --no-color --timestamps > "$run_dir/readiness-failure.log" 2>&1 || true
  echo "Security path failed readiness checks; evidence preserved at $run_dir" >&2
  exit 1
fi
"${args[@]}" ps > "$run_dir/container-state.txt"
docker image ls --digests --no-trunc > "$run_dir/image-inventory.txt"
printf 'Started %s %s as %s\nEvidence: %s\n' "$case_id" "$mode" "$experiment_id" "$run_dir"
