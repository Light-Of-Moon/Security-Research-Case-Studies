#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
case_id="${1:?usage: run-experiment.sh CVE-... mode-a|mode-b}"
mode="${2:?usage: run-experiment.sh CVE-... mode-a|mode-b}"
validate_mode "$mode"
run_link="$SCL_ROOT/evidence-runs/current"
[[ -L "$run_link" ]] || { echo "Start a case first" >&2; exit 1; }
run_dir="$(readlink -f "$run_link")"
export EVIDENCE_DIR="$run_dir" EXPERIMENT_ID="$(<"$run_dir/EXPERIMENT_ID")" CASE_ID="$case_id" LAB_MODE="$mode"
bash "$SCL_ROOT/cases/$case_id/scripts/test.sh"
mapfile -t files < <(compose_files "$case_id" "$mode")
args=(docker compose -p scl-lab)
for file in "${files[@]}"; do args+=(-f "$file"); done
for classification in public recognized_confidential unrecognized_restricted base64_recognized; do
  "${args[@]}" exec -T egress-tester python /opt/scl/test_client.py "$classification" \
    "$EXPERIMENT_ID" "$EXPERIMENT_ID-$classification" \
    >"$run_dir/egress/$classification.json" || true
done
"${args[@]}" exec -T egress-tester python -c \
  'import socket; socket.create_connection(("external-receiver",8080),3)' \
  >"$run_dir/egress/direct-bypass.stdout" 2>"$run_dir/egress/direct-bypass.stderr" && \
  printf 'FAIL direct receiver reachability\n' >"$run_dir/egress/direct-bypass.result" || \
  printf 'PASS direct receiver unreachable\n' >"$run_dir/egress/direct-bypass.result"
python3 "$SCL_ROOT/scripts/summarize-dlp-matrix.py" "$run_dir"
bash "$SCL_ROOT/scripts/verify-isolation.sh" "$case_id" "$mode"
# Allow the local Wazuh agent/manager pipeline to ingest the final control
# events before the immutable per-run export is taken.
sleep 10
bash "$SCL_ROOT/scripts/collect-evidence.sh" "$case_id" "$mode" live
