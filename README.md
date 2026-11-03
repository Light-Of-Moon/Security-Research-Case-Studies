# security research case studies

three docker labs and a review of app-builder security. we examined which controls saw an attack, which stopped it, and which only limited the damage.

## cves against security controls

| case | recorded result | added control |
| --- | --- | --- |
| [next.js / cve-2025-29927](labs/security-control-limits/cases/CVE-2025-29927/) | protected page returned without a session | independent session check redirected the bypass |
| [teamcity / cve-2024-27198](labs/security-control-limits/cases/CVE-2024-27198/) | unauthenticated administrator creation | method guard blocked the write; read bypass remained |
| [activemq / cve-2023-46604](labs/security-control-limits/cases/CVE-2023-46604/) | code execution and document transfer | segmentation limited data access; runtime monitoring raised an alert |

the key finding: **an alert does not prove prevention, and one blocked payload does not prove full coverage.** the reports explain the rule, decision and observed result for each case.

[lab setup](labs/security-control-limits/) · [seven reports](reports/)

## app builders and generated code

[published research](research/app-builders/) on ai-built apps, wordpress components and android generators. the cases cover ownership checks, payment state, platform authentication and database settings.

the report draws its evidence from published disclosures and research papers.

## members

- **[mohamed salah](https://www.linkedin.com/in/mohamed-salah-3a0498248/)** — security researcher / penetration tester · [hackerone](https://hackerone.com/lightofthemoon) · [hack the box](https://app.hackthebox.com/profile/2354735)
- **[ahmed hatem](https://www.linkedin.com/in/ahmed-hatem-0530742b2)** — web pentester
