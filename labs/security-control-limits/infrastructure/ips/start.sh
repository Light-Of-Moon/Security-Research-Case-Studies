#!/usr/bin/env bash
set -euo pipefail
target_host="${IPS_TARGET_HOST:?IPS_TARGET_HOST is required}"
target_port="${IPS_TARGET_PORT:?IPS_TARGET_PORT is required}"
target_ip="$(getent ahostsv4 "$target_host" | awk 'NR == 1 {print $1}')"
if [[ -z "$target_ip" ]]; then
  echo "IPS target resolution failed: $target_host" >&2
  exit 1
fi
suricata --build-info | grep -Eq 'NFQ|NFQUEUE' || {
  echo "Suricata build lacks NFQUEUE support" >&2
  exit 1
}
iptables -C OUTPUT -p tcp -d "$target_ip" --dport "$target_port" -j NFQUEUE --queue-num 0 2>/dev/null || \
  iptables -I OUTPUT 1 -p tcp -d "$target_ip" --dport "$target_port" -j NFQUEUE --queue-num 0
iptables -C INPUT -p tcp -s "$target_ip" --sport "$target_port" -j NFQUEUE --queue-num 0 2>/dev/null || \
  iptables -I INPUT 1 -p tcp -s "$target_ip" --sport "$target_port" -j NFQUEUE --queue-num 0
et_rules=/var/lib/suricata/rules/suricata.rules
test -s "$et_rules" || { echo "ET Open rules are missing" >&2; exit 1; }
cat "$et_rules" /etc/suricata/rules/lab.rules > /var/lib/suricata/rules/scl-active.rules
echo "Inline IPS: NFQUEUE 0 for $target_ip:$target_port"
exec suricata -c /etc/suricata/suricata.yaml \
  -S /var/lib/suricata/rules/scl-active.rules -l /var/log/suricata -q 0

