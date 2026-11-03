#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$root"
command="${1:-help}"
resolve() {
  case "${1:-}" in
    activemq|ActiveMQ|CVE-2023-46604) id=CVE-2023-46604 ;;
    nextjs|Next.js|CVE-2025-29927) id=CVE-2025-29927 ;;
    teamcity|TeamCity|CVE-2024-27198) id=CVE-2024-27198 ;;
    *) echo "Choose activemq, nextjs, or teamcity" >&2; exit 2;;
  esac
  mode="${2:-mode-a}"
  [[ "$mode" == mode-a || "$mode" == mode-b ]] || { echo "Mode must be mode-a or mode-b" >&2; exit 2; }
}
case "$command" in
  check) bash scripts/setup.sh ;;
  start)
    resolve "${2:-}" "${3:-mode-a}"
    if [[ -n "$(docker ps -q --filter label=com.docker.compose.project=scl-lab)" ]];then
       echo "An scl-lab stack is already running. Stop it before switching CVEs." >&2
       docker ps --filter label=com.docker.compose.project=scl-lab --format '{{.Names}}: {{.Status}}' >&2
       exit 1
    fi
    bash scripts/start-case.sh "$id" "$mode" ;;
  stop) resolve "${2:-}" "${3:-mode-a}"; bash scripts/stop-case.sh "$id" "$mode" ;;
  capture) resolve "${2:-}" "${3:-mode-a}"; bash scripts/collect-evidence.sh "$id" "$mode" live ;;
  automatic-test) resolve "${2:-}" "${3:-mode-a}"; bash scripts/run-experiment.sh "$id" "$mode" ;;
  status)
    docker ps --filter label=com.docker.compose.project=scl-lab --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
    [[ -L evidence-runs/current ]] && echo "Evidence: $(readlink -f evidence-runs/current)" || true ;;
  help|-h|--help)
    cat <<'USAGE'
Usage:
  ./lab.sh check
  ./lab.sh start activemq mode-a
  ./lab.sh status
  ./lab.sh capture activemq mode-a
  ./lab.sh stop activemq mode-a
  ./lab.sh start nextjs mode-a
  ./lab.sh start teamcity mode-b
  ./lab.sh automatic-test activemq mode-a  # optional, sends test payloads
Always stop one lab before starting another. Start does not run an exploit.
USAGE
    ;;
  *) echo "Unknown command: $command" >&2; exit 2;;
esac
