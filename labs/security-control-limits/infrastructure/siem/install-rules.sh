#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
manager="$(docker ps --filter label=com.docker.compose.service=wazuh.manager --format '{{.ID}}' | head -n1)"
[[ -n "$manager" ]] || { echo "Running shared Wazuh manager not found" >&2; exit 1; }
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="$root/backups/existing-lab-audit/wazuh-rules-$stamp.xml"
mkdir -p "$(dirname -- "$backup")"
had_old=no
if docker cp "$manager:/var/ossec/etc/rules/scl_rules.xml" "$backup" 2>/dev/null; then had_old=yes; fi
docker cp "$root/infrastructure/siem/scl_rules.xml" "$manager:/var/ossec/etc/rules/scl_rules.xml"
if ! docker exec "$manager" /var/ossec/bin/wazuh-analysisd -t; then
  if [[ "$had_old" == yes ]]; then
    docker cp "$backup" "$manager:/var/ossec/etc/rules/scl_rules.xml"
  else
    docker exec "$manager" rm -f /var/ossec/etc/rules/scl_rules.xml
  fi
  echo "Wazuh rule validation failed; prior state restored" >&2
  exit 1
fi
docker restart "$manager" >/dev/null
echo "Installed SCL Wazuh rules after syntax validation; prior file (if any): $backup"
