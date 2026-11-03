#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
run_id="${1:?usage: show-cli-proof.sh RUN_ID}"
run_dir="$root/evidence-runs/$run_id"
[[ -d "$run_dir" ]] || { echo "Unknown evidence run: $run_id" >&2; exit 1; }

case_id="$(<"$run_dir/CASE")"
mode="$(<"$run_dir/MODE")"

clear
printf '\033[1;36mSECURITY CONTROL LIMITS — LIVE CLI PROOF\033[0m\n'
printf 'Run:  %s\nCase: %s\nMode: %s\n\n' "$run_id" "$case_id" "$mode"

case "$case_id" in
  CVE-2023-46604)
    printf '\033[1;33mActiveMQ exploit and egress result\033[0m\n'
    sed -n '1,20p' "$run_dir/responses/experiment-verdict.txt" 2>/dev/null || true
    sed -n '1,14p' "$run_dir/responses/rce-classification-matrix.tsv" 2>/dev/null || true
    printf '\nRuntime proof:\n'
    sed -n '1,10p' "$run_dir/responses/rce-status.txt" 2>/dev/null || true
    ;;
  CVE-2025-29927)
    printf '\033[1;33mNext.js authorization matrix\033[0m\n'
    sed -n '1,15p' "$run_dir/responses/authorization-matrix.tsv"
    ;;
  CVE-2024-27198)
    printf '\033[1;33mTeamCity authentication-bypass impact matrix\033[0m\n'
    sed -n '1,15p' "$run_dir/responses/teamcity-impact-matrix.tsv"
    ;;
  *)
    echo "No CLI proof renderer for $case_id" >&2
    exit 1
    ;;
esac

printf '\n\033[1;32mEvidence directory:\033[0m %s\n' "$run_dir"
printf 'This window is displaying files captured from the real isolated lab run.\n'
printf '\nPress Enter to close.\n'
read -r _
