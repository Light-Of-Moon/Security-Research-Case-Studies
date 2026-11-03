#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
case_id="${1:?usage: stop-case.sh CVE-... mode-a|mode-b}"
mode="${2:?usage: stop-case.sh CVE-... mode-a|mode-b}"
validate_mode "$mode"
run_link="$SCL_ROOT/evidence-runs/current"
[[ -L "$run_link" ]] || { echo "No current run is selected" >&2; exit 1; }
run_dir="$(readlink -f "$run_link")"
[[ -r "$run_dir/CASE" && -r "$run_dir/MODE" ]] || {
  echo "Current run is missing CASE or MODE metadata" >&2
  exit 1
}
if [[ "$(<"$run_dir/CASE")" != "$case_id" || "$(<"$run_dir/MODE")" != "$mode" ]]; then
  echo "Refusing to stop $case_id $mode: current run is $(<"$run_dir/CASE") $(<"$run_dir/MODE")" >&2
  exit 1
fi
mapfile -t files < <(compose_files "$case_id" "$mode")
args=(docker compose -p scl-lab)
for file in "${files[@]}"; do args+=(-f "$file"); done
siem_profile=()
if docker network inspect single-node_default >/dev/null 2>&1; then
  siem_profile=(--profile siem)
fi
# Stop every service described by this case's Compose model, including the
# shared lab helpers that can still append health checks or normalized events.
# `stop` preserves containers, named volumes, networks, and evidence.
if [[ "$case_id" == CVE-2023-46604 ]]; then
  "${args[@]}" "${siem_profile[@]}" stop
else
  "${args[@]}" --profile web --profile ci-agent "${siem_profile[@]}" stop
fi

# Re-export after all writers are quiet. This makes SHA256SUMS.txt the stable,
# final manifest for the run rather than a checksum of a moving log directory.
bash "$SCL_ROOT/scripts/collect-evidence.sh" "$case_id" "$mode" final
echo "Stopped and finalized the selected case; containers, named volumes, networks, and evidence were preserved."
