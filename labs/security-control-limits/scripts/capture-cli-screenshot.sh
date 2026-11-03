#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
run_id="${1:?usage: capture-cli-screenshot.sh RUN_ID OUTPUT.png}"
output="${2:?usage: capture-cli-screenshot.sh RUN_ID OUTPUT.png}"
run_dir="$root/evidence-runs/$run_id"
[[ -r "$run_dir/CASE" && -r "$run_dir/MODE" ]] || {
  echo "Run metadata not found: $run_id" >&2
  exit 1
}

title="$(<"$run_dir/CASE") $(<"$run_dir/MODE") — real lab proof"
mkdir -p "$(dirname -- "$output")"

GDK_BACKEND=x11 ptyxis --standalone --maximize --title "$title" -- \
  bash "$root/scripts/show-cli-proof.sh" "$run_id" &
terminal_pid=$!
trap 'kill "$terminal_pid" 2>/dev/null || true' EXIT

window_id=""
for _attempt in $(seq 1 40); do
  window_id="$(xwininfo -root -tree -display :0 2>/dev/null | \
    awk -v needle="$title" 'index($0, needle) {print $1; exit}')"
  if [[ -n "$window_id" ]]; then
    window_width="$(xwininfo -display :0 -id "$window_id" 2>/dev/null | \
      awk '/Width:/ {print $2; exit}')"
    [[ "${window_width:-0}" -gt 1000 ]] && break
  fi
  sleep 0.25
done
[[ -n "$window_id" ]] || { echo "Could not locate terminal window: $title" >&2; exit 1; }

# The X11 window can be mapped before the terminal surface has painted. Wait
# briefly so the capture contains the actual evidence text rather than an
# uninitialized black surface.
sleep 1
import -display :0 -window "$window_id" "$output"
file "$output"
sha256sum "$output"
