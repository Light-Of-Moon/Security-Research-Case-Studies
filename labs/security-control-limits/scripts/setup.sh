#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
for command in docker curl sha256sum; do
  command -v "$command" >/dev/null || { echo "Missing dependency: $command" >&2; exit 1; }
done
docker compose version >/dev/null
docker info >/dev/null 2>&1 || { echo "Docker is unavailable" >&2; exit 1; }
[[ "$(uname -s)" == Linux ]] || { echo "Inline NFQUEUE mode requires Linux" >&2; exit 1; }
if docker info --format '{{json .SecurityOptions}}' | grep -qi rootless; then
  echo "Inline NFQUEUE mode requires rootful Docker" >&2; exit 1
fi
if docker compose version --short | grep -q .; then
  echo "Docker Compose version: $(docker compose version --short)"
fi
bash "$root/scripts/verify-all.sh"
echo "Ready. Only one CVE stack can be running at once."
