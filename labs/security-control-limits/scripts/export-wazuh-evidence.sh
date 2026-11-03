#!/usr/bin/env bash
set -euo pipefail

run_dir="${1:?usage: export-wazuh-evidence.sh RUN_DIRECTORY}"
run_dir="$(readlink -f "$run_dir")"
experiment_id="$(<"$run_dir/EXPERIMENT_ID")"
manager="${WAZUH_MANAGER_CONTAINER:-single-node-wazuh.manager-1}"
mkdir -p "$run_dir/siem"

if ! docker inspect -f '{{.State.Running}}' "$manager" 2>/dev/null | grep -qx true; then
  printf 'Wazuh manager container unavailable: %s\n' "$manager" >"$run_dir/siem/EXPORT_FAILURE.txt"
  exit 0
fi

docker exec "$manager" grep -F "$experiment_id" /var/ossec/logs/archives/archives.json \
  >"$run_dir/siem/wazuh-archives.jsonl" || true
docker exec "$manager" grep -F "$experiment_id" /var/ossec/logs/alerts/alerts.json \
  >"$run_dir/siem/wazuh-alerts.jsonl" || true

printf 'Exported %s archive events and %s alerts for %s\n' \
  "$(wc -l <"$run_dir/siem/wazuh-archives.jsonl")" \
  "$(wc -l <"$run_dir/siem/wazuh-alerts.jsonl")" "$experiment_id"
