# working apps, missing checks

a review of published disclosures and studies on ai-built apps, visual builders and generated android apps.

| case | missing check | evidence |
| --- | --- | --- |
| [linkable / 2025](https://mattpalmer.io/posts/2025/05/statement-on-CVE-2025-48757/) | ownership and payment state | researcher inserted a record marked paid; broader lovable cve is disputed |
| [moltbook / 2026](https://www.wiz.io/blog/exposed-moltbook-database-reveals-millions-of-api-keys) | database access and post ownership | exposed tokens and demonstrated unauthorized changes |
| [base44 / 2025](https://www.wiz.io/blog/critical-vulnerability-base44) | private-app membership | registration bypass confirmed and fixed by the platform |
| [wordpress addon / 2023](https://patchstack.com/articles/critical-privilege-escalation-in-essential-addons-for-elementor-plugin-affecting-1-million-sites/) | password-reset validation | cve-2023-32243; [wordfence observed exploit attempts](https://www.wordfence.com/blog/2023/05/psa-attackers-actively-exploiting-critical-vulnerability-in-essential-addons-for-elementor/) |
| [android generators / 2018](https://conferences.computer.org/sp/pdfs/sp/2018/TheRiseoftheCitizenDeveloperAssessingth.pdf) | shared configuration and component boundaries | peer-reviewed analysis of generated apps |
| [firebase mobile apps / 2022](https://blog.checkpoint.com/security/stop-neglecting-your-cloud-security-features-check-point-research-found-thousands-of-open-cloud-databases-exposing-data-in-the-wild/) | backend database restrictions | deployed exposures; development method was not established |

**finding:** a working login, form or checkout does not prove that the backend enforces ownership or business rules. apps can inherit flaws from a shared platform, plugin or generated template.

the evidence supports checking those boundaries in every approach. it does not prove that ai caused every weakness or rank all builders against human developers. the older android study also does not describe current product versions.

[full report: screenshots, study methods, fixes and references](../../reports/app_builders_security_research.pdf)
