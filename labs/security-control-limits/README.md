# three cves against security controls

docker compose source for the [next.js](cases/CVE-2025-29927/), [teamcity](cases/CVE-2024-27198/) and [activemq](cases/CVE-2023-46604/) experiments. recorded findings are in the [reports](../../reports/).

## controls

web cases use modsecurity crs 4.12.0, suricata inline nfqueue, response and egress dlp, and internal docker networks. crs starts at pl2 with inbound threshold 5 and outbound threshold 4. activemq uses haproxy for openwire instead of an http waf.

| source configuration | additional control |
| --- | --- |
| next.js `mode-b` | independent route and synthetic-session enforcement |
| teamcity `mode-b` | crs pl3; guard for unauthenticated post, put, patch and delete; login-submit exception |
| activemq `mode-b` | broker removed from the protected network; java child-process monitoring |

`mode-a` and `mode-b` are the script names. the case readmes describe their actual policies. wazuh is optional and connects through an existing `single-node_default` network; local sensors still produce logs without it.

for custom siem alerts, `bash infrastructure/siem/install-rules.sh` validates and installs the supplied rules, then restarts the existing wazuh manager.

## run

use linux, python 3, curl, rootful docker and compose v2 with `!override` support (2.24.4+). first setup downloads images; teamcity needs substantial disk and memory. run one case at a time on an isolated, authorized machine.

```bash
git clone https://github.com/Light-Of-Moon/Security-Research-Case-Studies.git
cd Security-Research-Case-Studies/labs/security-control-limits
./lab.sh check
./lab.sh start nextjs mode-a
./lab.sh automatic-test nextjs mode-a
./lab.sh capture nextjs mode-a
./lab.sh stop nextjs mode-a
```

`start` only starts services. `automatic-test` sends the lab probes and checks. substitute `teamcity` or `activemq`, and stop the current case before switching configurations.

http ingress is `127.0.0.1:18080`; openwire ingress is `127.0.0.1:16116`. targets and the synthetic receiver stay on internal networks. fresh results go to `evidence-runs/<experiment-id>/`; stopping finalizes the snapshot and its checksums.

## read the result

check the application outcome, sensor action and receiver record together. keep classifier probes separate from exploit-linked transfers. the receiver is a lab container, and root in the activemq container does not establish host compromise.

the repository includes source and report screenshots. raw historical logs, pcaps and docker image layers are not included. patched-reference helpers are retained as test utilities; their presence is not a claim that every reference was run.

check source integrity from this directory with `sha256sum -c SHA256SUMS.txt`.
