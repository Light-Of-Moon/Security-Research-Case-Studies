<p align="center">
  <img src="assets/banner.png" alt="Security research case studies — three lab cases and seven reports" width="100%">
</p>

<p align="center">
  <a href="#recorded-results">Results</a> ·
  <a href="#report-library">Reports</a> ·
  <a href="labs/security-control-limits/">Lab setup</a> ·
  <a href="evidence/README.md">Evidence</a> ·
  <a href="references/README.md">Published sources</a> ·
  <a href="research/app-builders/">App-builder research</a>
</p>

[Open the visual overview](index.html) after extracting the ZIP.

We tested three CVEs in Docker labs to see which controls noticed an attack, which stopped it, and which limited what happened next. A separate report reviews published security research on app builders and generated code.

**An alert does not prove prevention. One blocked payload does not prove full coverage.**


<table>
<tr>
<td width="33%" align="center"><a href="evidence/nextjs/README.md"><img src="assets/logos/nextjs.svg" width="150" alt="Next.js logo"></a></td>
<td width="33%" align="center"><a href="evidence/teamcity/README.md"><img src="assets/logos/teamcity.png" width="150" alt="TeamCity logo"></a></td>
<td width="33%" align="center"><a href="evidence/activemq/README.md"><img src="assets/logos/activemq.svg" width="150" alt="ActiveMQ logo"></a></td>
</tr>
</table>

## Report library

Click a case card to open the control report. The manual reports contain the separate Burp or command-execution captures.

<table>
<tr>
<td width="33%" align="center">
<a href="reports/nextjs_cve-2025-29927_security_controls.pdf"><img src="assets/cases/nextjs.png" width="300" alt="Next.js security tool responses report cover"></a><br>
<strong>Next.js / middleware bypass</strong><br>
<a href="evidence/nextjs/README.md"><strong>Open evidence index ↗</strong></a><br>
<a href="reports/nextjs_cve-2025-29927_report.pdf">Manual test · 3 pages</a><br>
<a href="reports/nextjs_cve-2025-29927_security_controls.pdf">Control responses · 6 pages</a>
</td>
<td width="33%" align="center">
<a href="reports/teamcity_cve-2024-27198_security_controls.pdf"><img src="assets/cases/teamcity.png" width="300" alt="TeamCity security tool responses report cover"></a><br>
<strong>TeamCity / authentication bypass</strong><br>
<a href="evidence/teamcity/README.md"><strong>Open evidence index ↗</strong></a><br>
<a href="reports/teamcity_cve-2024-27198_report.pdf">Manual test · 3 pages</a><br>
<a href="reports/teamcity_cve-2024-27198_security_controls.pdf">Control responses · 6 pages</a>
</td>
<td width="33%" align="center">
<a href="reports/activemq_cve-2023-46604_security_controls.pdf"><img src="assets/cases/activemq.png" width="300" alt="ActiveMQ security tool responses report cover"></a><br>
<strong>ActiveMQ / code execution</strong><br>
<a href="evidence/activemq/README.md"><strong>Open evidence index ↗</strong></a><br>
<a href="reports/activemq_cve-2023-46604_report.pdf">Manual test · 3 pages</a><br>
<a href="reports/activemq_cve-2023-46604_security_controls.pdf">Control responses · 6 pages</a>
</td>
</tr>
</table>

Manual captures and control experiments are separate evidence sets. Compare outcomes within the configuration described in each report.

### Working apps, missing checks

<table>
<tr>
<td width="47%" align="center"><a href="reports/app_builders_security_research.pdf"><img src="assets/cases/app-builders.png" width="420" alt="Working apps, missing checks research report cover"></a></td>
<td>
<strong>App builders and generated code</strong>
<p>A review of published disclosures and studies covering Linkable, Moltbook, Base44, Escape, WordPress components, Android generators and Firebase-backed apps.</p>
<p>The cases focus on ownership checks, payment state, platform authentication and database settings. They do not establish that AI caused every weakness or rank builders against human developers.</p>
<a href="reports/app_builders_security_research.pdf"><strong>Read the report · 10 pages</strong></a><br><br>
<a href="research/app-builders/">Case summaries and original sources</a>
</td>
</tr>
</table>

## Recorded results

These results come from the control experiments. Each report keeps the application outcome separate from the sensor's decision.

| Case | Before the extra control | With the extra control | What it showed |
| :--- | :--- | :--- | :--- |
| **[Next.js](labs/security-control-limits/cases/CVE-2025-29927/)**<br>CVE-2025-29927 | Forged middleware header returned the protected page without a session: **200** | Independent session check returned **307** | The gateway enforced the missing authorization check. |
| **[TeamCity](labs/security-control-limits/cases/CVE-2024-27198/)**<br>CVE-2024-27198 | An unauthenticated request created a synthetic administrator: **200** | Method guard blocked the external write: **403**; bypassed reads still returned **200** | Blocking the write did not close the read bypass. |
| **[ActiveMQ](labs/security-control-limits/cases/CVE-2023-46604/)**<br>CVE-2023-46604 | Code execution succeeded; an unrecognized **186-byte** document reached the receiver | Code execution still succeeded; segmentation made protected documents unavailable and runtime monitoring raised an alert | Containment limited the later data-access step. |

The web cases used ModSecurity CRS, inline Suricata, DLP and Docker isolation. ActiveMQ used HAProxy on the binary OpenWire path. Wazuh supplied recorded telemetry; the individual reports explain which component enforced each decision.

## Follow the evidence

Each case has a screenshot index with direct links to its PDF pages. Selected archive records keep their original JSON, line number and experiment ID.

| Case | Screenshots and context | Key report pages | Exact archive records |
| :--- | :--- | :--- | :--- |
| Next.js | [Evidence index](evidence/nextjs/README.md) | [Allowed request, p. 2](reports/nextjs_cve-2025-29927_security_controls.pdf#page=2) · [Session check, p. 3](reports/nextjs_cve-2025-29927_security_controls.pdf#page=3) | [Allowed](evidence/records/nextjs-allowed.json) · [Denied](evidence/records/nextjs-denied.json) |
| TeamCity | [Evidence index](evidence/teamcity/README.md) | [Method guard, p. 3](reports/teamcity_cve-2024-27198_security_controls.pdf#page=3) | [Guard decision](evidence/records/teamcity-guard.json) |
| ActiveMQ | [Evidence index](evidence/activemq/README.md) | [IPS, p. 2](reports/activemq_cve-2023-46604_security_controls.pdf#page=2) · [Containment, p. 4](reports/activemq_cve-2023-46604_security_controls.pdf#page=4) | [IPS alert](evidence/records/activemq-ips.json) · [Runtime alert](evidence/records/activemq-monitor.json) |
| App builders | [Published-source captures](evidence/app-builders/README.md) | [Full report](reports/app_builders_security_research.pdf) | [Original publications](research/app-builders/README.md) |

[All 45 captures](evidence/README.md) · [Record provenance and hashes](evidence/manifest.json) · [Full archive](logs/three_cve_logs_available_records.txt)

Use matching experiment IDs when correlating archive events. Manual captures, control experiments and public disclosures retain their own evidence context.

## Advisories and incident research

| Product | Publication | Publisher | Date |
| :--- | :--- | :--- | :--- |
| Next.js | [Next.js middleware-bypass postmortem](https://vercel.com/blog/postmortem-on-next-js-middleware-bypass) | Vercel | 2025-03-25 |
| TeamCity | [TeamCity authentication-bypass advisory](https://blog.jetbrains.com/teamcity/2024/03/additional-critical-security-issues-affecting-teamcity-on-premises-cve-2024-27198-and-cve-2024-27199-update-to-2023-11-4-now/) | JetBrains | 2024-03-04 |
| ActiveMQ | [Suspected ActiveMQ exploitation and ransomware activity](https://www.rapid7.com/blog/post/2023/11/01/etr-suspected-exploitation-of-apache-activemq-cve-2023-46604/) | Rapid7 | 2023-11-01 |
| App builders | [Moltbook database exposure](https://www.wiz.io/blog/exposed-moltbook-database-reveals-millions-of-api-keys) | Wiz | 2026-02-02 |

[All eight sources and their context](references/README.md). Dates refer to the original publications.

## Run the labs

The [lab guide](labs/security-control-limits/) covers requirements, setup, configurations and evidence collection. It includes the full command sequence; the case guides explain the policies behind `mode-a` and `mode-b`.

| Lab | Case guide | Test script |
| :--- | :--- | :--- |
| Next.js 15.2.2 | [Session enforcement](labs/security-control-limits/cases/CVE-2025-29927/) | [test.sh](labs/security-control-limits/cases/CVE-2025-29927/scripts/test.sh) |
| TeamCity 2023.11.3 | [Routing and method guard](labs/security-control-limits/cases/CVE-2024-27198/) | [test.sh](labs/security-control-limits/cases/CVE-2024-27198/scripts/test.sh) |
| ActiveMQ 5.17.3 | [OpenWire and containment](labs/security-control-limits/cases/CVE-2023-46604/) | [test.sh](labs/security-control-limits/cases/CVE-2023-46604/scripts/test.sh) |

<details>
<summary><strong>Files and evidence</strong></summary>

| Location | Contents |
| :--- | :--- |
| [`evidence/`](evidence/README.md) | Screenshot gallery, page mappings and original log excerpts |
| [`references/`](references/README.md) | Dated vendor advisories and incident research |
| [`cases/`](cases/nextjs.html) | Case pages for the HTML overview |
| [`reports/`](reports/) | Seven PDF reports with screenshots, findings and references |
| [`labs/security-control-limits/`](labs/security-control-limits/) | Docker Compose source, control policies, test scripts and evidence helpers |
| [`research/app-builders/`](research/app-builders/) | Published case summaries and source links |
| [`logs/three_cve_logs_available_records.txt`](logs/three_cve_logs_available_records.txt) | Available historical log records supplied with this project |

The receiver is a lab container. Root inside the ActiveMQ container does not establish host compromise. Patched-reference helpers are test utilities; their presence does not establish that every reference was run.

</details>

## Members

| Researcher | Work | Links |
| :--- | :--- | :--- |
| **Mohamed Salah** | Security researcher / penetration tester | [LinkedIn](https://www.linkedin.com/in/mohamed-salah-3a0498248/) · [HackerOne](https://hackerone.com/lightofthemoon) · [Hack The Box](https://app.hackthebox.com/profile/2354735) |
| **Ahmed Hatem** | Web pentester | [LinkedIn](https://www.linkedin.com/in/ahmed-hatem-0530742b2) |

[Product logo sources](assets/logos/README.md)
