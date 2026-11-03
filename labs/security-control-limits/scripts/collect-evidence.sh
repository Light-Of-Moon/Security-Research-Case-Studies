#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
case_id="${1:?usage: collect-evidence.sh CVE-... mode-a|mode-b}"
mode="${2:?usage: collect-evidence.sh CVE-... mode-a|mode-b}"
phase="${3:-live}"
validate_mode "$mode"
[[ "$phase" == live || "$phase" == final ]] || {
  echo "Phase must be live or final" >&2
  exit 2
}
run_dir="$(readlink -f "$SCL_ROOT/evidence-runs/current")"
[[ -r "$run_dir/CASE" && -r "$run_dir/MODE" ]] || {
  echo "Current run is missing CASE or MODE metadata" >&2
  exit 1
}
if [[ "$(<"$run_dir/CASE")" != "$case_id" || "$(<"$run_dir/MODE")" != "$mode" ]]; then
  echo "Refusing to collect $case_id $mode: current run is $(<"$run_dir/CASE") $(<"$run_dir/MODE")" >&2
  exit 1
fi
if [[ -f "$run_dir/FINALIZED" ]]; then
  if [[ "$phase" == final ]]; then
    (cd "$run_dir" && sha256sum -c SHA256SUMS.txt)
    echo "Final snapshot already exists and verifies: $run_dir"
    exit 0
  fi
  echo "Refusing to modify finalized evidence: $run_dir" >&2
  exit 1
fi
mapfile -t files < <(compose_files "$case_id" "$mode")
args=(docker compose -p scl-lab)
for file in "${files[@]}"; do args+=(-f "$file"); done
"${args[@]}" ps > "$run_dir/container-state-after.txt" || true
"${args[@]}" logs --no-color --timestamps > "$run_dir/logs/compose.log" 2>&1 || true
docker network inspect scl_simulated_internet scl_application scl_protected_internal scl_egress \
  > "$run_dir/network-inspect.json" 2>"$run_dir/network-inspect.stderr" || true
bash "$SCL_ROOT/scripts/export-wazuh-evidence.sh" "$run_dir" || true
if [[ "$phase" == live ]]; then
  printf 'Live capture completed at %s; background writers may still be active.\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$run_dir/LIVE_CAPTURE.txt"
  echo "Live evidence captured without a final manifest: $run_dir"
  exit 0
fi

printf 'Finalized at %s after the selected Compose services were stopped.\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$run_dir/FINALIZED"
rm -f "$run_dir/LIVE_CAPTURE.txt"
(
  cd "$run_dir"
  find . -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum \
    > SHA256SUMS.txt
  if grep -qE '  /' SHA256SUMS.txt; then
    echo "Refusing non-portable absolute paths in final manifest" >&2
    exit 1
  fi
  sha256sum -c SHA256SUMS.txt >/dev/null
)
case_dest="$SCL_ROOT/cases/$case_id/$mode/evidence"
mkdir -p "$case_dest"
printf '%s\n' "evidence-runs/$(basename "$run_dir")" > "$case_dest/LATEST_RUN.txt"
cp "$run_dir/SHA256SUMS.txt" "$case_dest/SHA256SUMS.txt"
# Several security containers deliberately write logs as an unprivileged UID
# different from the invoking researcher. Those files are already not writable
# by the researcher, so a failed chmod on them is not an integrity failure.
chmod -R a-w "$run_dir" 2>/dev/null || true
if find "$run_dir" -writable -print -quit | grep -q .; then
  echo "Final snapshot still contains researcher-writable paths" >&2
  exit 1
fi
echo "Portable read-only final snapshot created: $run_dir"
