#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$root"
command -v docker >/dev/null || { echo "Docker not available" >&2; exit 1; }
command -v gzip >/dev/null || { echo "gzip not available" >&2; exit 1; }
# Only include images actually required for the three selected cases and the shared controls.
# Image layers can be very large (TeamCity several gigabytes). No container volumes
# or local team data are included.
images=(
  'python:3.12-alpine'
  'curlimages/curl:8.12.1'
  'owasp/modsecurity-crs:4.12.0-nginx-202503230103'
  'vulhub/nextjs:15.2.2'
  'vulhub/activemq:5.17.3'
  'nginx:1.27-alpine'
  'haproxy:2.9-alpine'
  'jetbrains/teamcity-server:2023.11.3'
)
# Build images are tagged under the original Compose project name.
for built in response-dlp egress-gateway internal-assets external-receiver ips openwire-ips authorization-gateway runtime-monitor; do
  images+=("scl-lab-$built:latest")
done
# The digest-pinned TeamCity image has to be present locally and tagged by its
# standard version tag. Pull with the Compose file on an online machine first.
missing=()
for img in "${images[@]}"; do
  if ! docker image inspect "$img" >/dev/null 2>&1; then missing+=("$img"); fi
done
if ((${#missing[@]}));then
  echo "Missing images on this host:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  echo "Start/stop all three cases and both modes (or build/pull their images) before exporting." >&2
  exit 1
fi
output="${1:-$root/three-cve-docker-images.tar.gz}"
if [[ -e "$output" ]];then echo "Refusing to overwrite: $output" >&2;exit 1;fi
printf 'Exporting %s images; this may use several GB of disk.\n' "${#images[@]}"
docker save "${images[@]}" | gzip -1 > "$output"
sha256sum "$output" > "$output.sha256"
echo "Created $output"
echo "On a teammate machine: sha256sum -c $(basename "$output").sha256 && gunzip -c $(basename "$output") | docker load"
echo "NOTE: The TeamCity Compose file uses an immutable registry digest; imported tag-only images may still require registry digest verification."
