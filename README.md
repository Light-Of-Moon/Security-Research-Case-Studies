<p align="center">
  <img src="assets/research-overview.png" alt="DEPI security research overview" width="100%">
</p>

<h1 align="center">Security Research Case Studies</h1>
<p align="center"><strong>Digital Egypt Pioneers Initiative (DEPI) · Vulnerability Analysis &amp; Penetration Testing</strong></p>
<p align="center">
  <a href="#objective-1--security-control-limits">Objective 01</a> ·
  <a href="#objective-2--application-development-security">Objective 02</a> ·
  <a href="cases/README.md">Case files</a> ·
  <a href="reports/README.md">Reports</a> ·
  <a href="evidence/README.md">Evidence</a> ·
  <a href="references/README.md">Sources</a>
</p>

Two questions drive this project:

- **What can security controls actually detect, block or contain?**
- **What vulnerabilities keep appearing across different development approaches?**

<table>
<tr>
<td width="50%" valign="top">
<strong>01 / EXPERIMENTAL RESEARCH</strong><br><br>
<strong>What can controls see and stop?</strong><br>
Three Docker lab cases. Two configurations. Focus on detection, prevention and containment.<br><br>
<a href="#objective-1--security-control-limits"><strong>Open objective 01 →</strong></a>
</td>
<td width="50%" valign="top">
<strong>02 / PUBLISHED RESEARCH</strong><br><br>
<strong>What vulnerabilities appear in each approach?</strong><br>
Source-backed comparison across vibe coding, app builders and conventional development.<br><br>
<a href="#objective-2--application-development-security"><strong>Open objective 02 →</strong></a>
</td>
</tr>
</table>

---

## Objective 1 — Security control limits

**Question:** What can WAF, IPS, SIEM, DLP, authorization checks and segmentation actually do when the application is vulnerable?

### Case files

<table>
<tr>
<td width="33%" align="center"><a href="cases/nextjs.md"><img src="assets/cases/nextjs.png" width="300" alt="Next.js case file"></a><br><strong>Next.js</strong><br><code>CVE-2025-29927</code><br>Middleware authorization bypass<br><br><a href="cases/nextjs.md"><strong>Open case study →</strong></a><br><a href="reports/nextjs_cve-2025-29927_report.pdf">Manual report</a> · <a href="reports/nextjs_cve-2025-29927_security_controls.pdf">Controls report</a></td>
<td width="33%" align="center"><a href="cases/teamcity.md"><img src="assets/cases/teamcity.png" width="300" alt="TeamCity case file"></a><br><strong>TeamCity</strong><br><code>CVE-2024-27198</code><br>Authentication bypass<br><br><a href="cases/teamcity.md"><strong>Open case study →</strong></a><br><a href="reports/teamcity_cve-2024-27198_report.pdf">Manual report</a> · <a href="reports/teamcity_cve-2024-27198_security_controls.pdf">Controls report</a></td>
<td width="33%" align="center"><a href="cases/activemq.md"><img src="assets/cases/activemq.png" width="300" alt="ActiveMQ case file"></a><br><strong>ActiveMQ</strong><br><code>CVE-2023-46604</code><br>Remote code execution<br><br><a href="cases/activemq.md"><strong>Open case study →</strong></a><br><a href="reports/activemq_cve-2023-46604_report.pdf">Manual report</a> · <a href="reports/activemq_cve-2023-46604_security_controls.pdf">Controls report</a></td>
</tr>
</table>

### Results at a glance

| Case | Configuration 1 | Configuration 2 | Takeaway |
| :--- | :--- | :--- | :--- |
| [Next.js](cases/nextjs.md) | Protected page returned **200** | Session check redirected **307** | Independent authorization stopped the tested bypass. |
| [TeamCity](cases/teamcity.md) | Unauthenticated admin creation **200** | Write blocked **403**; bypassed reads still **200** | Partial prevention, not a full fix. |
| [ActiveMQ](cases/activemq.md) | RCE succeeded; unrecognized document reached receiver | RCE still succeeded; protected documents unavailable | Segmentation contained the later step. |

### What the controls can see and do

| Control | What it saw | What it did / limit |
| :--- | :--- | :--- |
| ModSecurity / OWASP CRS | HTTP requests and rule matches | Blocked a separate TeamCity static-asset request; did not reliably stop the tested bypasses. |
| Suricata IPS | Network signatures and positive-control probes | Dropped test probes; recorded TeamCity and ActiveMQ exploit signatures as allowed. |
| Wazuh SIEM | Alerts, authorization decisions, DLP and runtime telemetry | Correlated evidence; no independent prevention established. |
| DLP gateways | Content markers and transfer metadata | Blocked recognized samples; unrecognized content still passed in some cases. |
| Authorization checks / method guard | Session state and missing credential indicators | Stopped the Next.js bypass; blocked TeamCity writes only. |
| Docker segmentation | Network reachability and downstream access | Contained the later ActiveMQ step; did not prevent RCE. |
| Runtime monitor | Unexpected child processes | Detected post-exploitation behavior; did not stop execution. |

> [!IMPORTANT]
> Alerts are not the same as prevention. Blocked probes are not proof of full coverage. These results apply to the recorded lab configurations only.

[Lab setup](labs/security-control-limits/README.md) · [Experimental reports](reports/README.md) · [Evidence index](evidence/README.md)

---

## Objective 2 — Application development security

**Question:** What vulnerability classes are documented across vibe coding, app builders and conventional development, and what security boundary failed in each case?

<table><tr>
<td width="44%" align="center"><a href="cases/app-builders.md"><img src="assets/cases/app-builders.png" width="410" alt="Working apps, missing checks research case"></a></td>
<td valign="middle"><strong>Working apps, missing checks</strong><br><br>Published research on authorization, data exposure, shared platform flaws, generated mobile components and deployment mistakes.<br><br><a href="cases/app-builders.md"><strong>Open research case study →</strong></a><br><a href="reports/app_builders_security_research.pdf">Full research report · 10 pages</a><br><a href="research/app-builders/README.md">Published source index</a></td>
</tr></table>

### Vulnerability types by development approach

| Approach | Published examples | Documented vulnerability classes |
| :--- | :--- | :--- |
| Vibe coding / AI-built apps | Linkable, Moltbook, Lovable | Broken access control, payment-state manipulation, broken ownership checks, exposed records and secrets. |
| App builders / hosted builders | Base44, Elementor add-ons, Android generators | Membership bypass, weak reset flows, shared template flaws, exposed components and inherited platform risk. |
| Human development / deployment | Firebase exposures, conventional coding studies | Public database access, insecure programming solutions, weak backend checks and misconfiguration. |

The classes overlap. The evidence shows recurring boundary failures, not a universal ranking of one approach against another.

[App-builders case file](cases/app-builders.md) · [Research sources](research/app-builders/README.md) · [Full report](reports/app_builders_security_research.pdf)

---

## Project structure

| Path | Purpose |
| :--- | :--- |
| [`cases/`](cases/README.md) | GitHub-readable case studies |
| [`reports/`](reports/README.md) | Seven PDF reports |
| [`evidence/`](evidence/README.md) | 45 captures, mappings and manifests |
| [`references/`](references/README.md) | Source list for the project |
| [`labs/security-control-limits/`](labs/security-control-limits/README.md) | Docker lab source and setup |
| [`research/app-builders/`](research/app-builders/README.md) | Published-source notes for objective 02 |

## Notes

- The three CVE cases were reproduced in isolated Docker environments.
- The app-builders case is a literature and disclosure review, not a reproduced exploit set.
- Report content was preserved; only visual presentation assets were refreshed in this edition.
