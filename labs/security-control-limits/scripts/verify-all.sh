#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
fail=0
for case_dir in "$SCL_ROOT"/cases/CVE-*; do
  case_id="$(basename "$case_dir")"
  for mode in mode-a mode-b; do
    mapfile -t files < <(compose_files "$case_id" "$mode")
    args=(docker compose -p scl-verify)
    for file in "${files[@]}"; do args+=(-f "$file"); done
    if ! CASE_BACKEND="$(case_backend "$case_id")" "${args[@]}" config -q; then
      echo "FAIL compose: $case_id $mode" >&2
      fail=1
    fi
  done
  for required in README.md docker-compose.yml scripts/test.sh; do
    [[ -s "$case_dir/$required" ]] || { echo "FAIL missing: $case_id/$required" >&2; fail=1; }
  done
done
for script in "$SCL_ROOT"/scripts/*.sh "$SCL_ROOT"/cases/*/scripts/*.sh; do
  bash -n "$script" || fail=1
done
if [[ "$fail" == 0 ]]; then echo "Static verification passed."; fi
exit "$fail"

