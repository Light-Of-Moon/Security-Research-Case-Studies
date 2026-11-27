[← Project overview](../README.md) · [All cases](README.md) · [Published sources](../references/README.md)

# App builders and generated code

**OBJECTIVE 02 — PUBLISHED RESEARCH** · Application development security

<table><tr><td width="44%"><img src="../assets/cases/app-builders.png" width="390" alt="Working apps, missing checks report cover"></td><td><strong>Working apps, missing checks.</strong><br><br>A compact, source-backed comparison of recurring vulnerabilities across vibe coding, app builders and conventional development.<br><br>This page summarizes published evidence. It does not claim that every weakness was caused by AI, nor that one approach is always less secure than another.<br><br><a href="../reports/app_builders_security_research.pdf"><strong>Open the full report →</strong></a></td></tr></table>

## Core question

**What types of vulnerabilities appear across different development approaches, and what security boundary failed in each case?**

## Three-way vulnerability comparison

| Vulnerability class | Vibe coding / AI-built apps | App builders / generated platforms | Human development / deployment | Example references |
| :--- | :--- | :--- | :--- | :--- |
| Broken access control | Linkable payment-state abuse; Moltbook record ownership issues | Base44 private-app registration bypass | Common backend ownership and role failures | [1], [2], [3], [8] |
| Sensitive data exposure | Moltbook exposed API keys and records; Lovable apps exposed personal data | Public or overly broad builder/database integrations | Open Firebase databases and exposed cloud records | [2], [4], [9] |
| Business logic flaws | Client-controlled payment or completion state | Visual workflows that trust frontend state | Server logic that trusts unverified client actions | [1], [8] |
| Authentication / account recovery flaws | Shared hosted-auth assumptions can fail | Elementor password-reset flaw (CVE-2023-32243) | Conventional applications can implement weak recovery logic too | [5], [8] |
| Misconfiguration / insecure defaults | Public deployments with unsafe defaults | Builder or platform defaults can leave data too open | Deployment errors remain common in manual stacks | [4], [9] |
| Shared component / template risk | Repeated patterns across generated apps | Shared plugins, generators and common templates spread the same flaw | Reused libraries and frameworks can do the same | [5], [7], [8] |
| Insecure programming solutions | Controlled study showed more insecure solutions under AI assistance in some tasks | Low-code custom handlers still need secure logic | Human-written code can still contain the same flaw classes | [8] |

## What this comparison supports

- **The vulnerability classes overlap.** The main difference is often *where* the trust boundary failed.
- **Vibe coding** often concentrates risk around backend authorization, exposed data and over-trusted generated logic.
- **App builders** add platform, plugin and shared-template risk.
- **Human development** still produces the same broad classes of bugs, especially access-control and configuration failures.

## Minimal takeaway table

| Approach | Main boundary to verify |
| :--- | :--- |
| Vibe coding | Backend authorization and exposed data paths |
| App builders | Platform rules, plugins, generated components and shared defaults |
| Human development | Backend logic, configuration and release-time validation |

## Featured examples

### Lovable / exposed sensitive data

Crissy Field analyzed **159,041 Lovable projects** and reported that many applications exposed sensitive data without requiring login. Their sample found 24,664 sites returning Supabase records on load, and further read-only requests uncovered email-address-containing tables on 7,403 of those sites.[4]

### Base44 / private-app membership bypass

Wiz documented a platform flaw where a private Base44 application could still be joined through registration, allowing account creation despite the intended private-access setting.[3]

### Moltbook / ownership and data exposure

Wiz reported exposed API keys and unauthorized modification paths in Moltbook, illustrating both sensitive-data exposure and record-ownership failure.[2]

## References

1. Matt Palmer, **Statement on CVE-2025-48757** (29 May 2025). Linkable payment-state / ownership discussion. <https://mattpalmer.io/posts/2025/05/statement-on-CVE-2025-48757/>
2. Wiz Research, **Exposed Moltbook Database Reveals Millions of API Keys** (2 February 2026). <https://www.wiz.io/blog/exposed-moltbook-database-reveals-millions-of-api-keys>
3. Wiz Research, **Critical Vulnerability in Base44** (2025). <https://www.wiz.io/blog/critical-vulnerability-base44>
4. Crissy Field GmbH, **Lovable: Many Apps Built on the Platform Expose Sensitive Data** (2026). <https://www.crissyfield.de/research/lovable-en/>
5. Patchstack, **Critical Privilege Escalation in Essential Addons for Elementor** (2023). <https://patchstack.com/articles/critical-privilege-escalation-in-essential-addons-for-elementor-plugin-affecting-1-million-sites/>
6. Escape, **Methodology — How We Discovered Vulnerabilities in Apps Built with Vibe Coding** (29 October 2025). <https://escape.tech/blog/methodology-how-we-discovered-vulnerabilities-apps-built-with-vibe-coding/>
7. Oltrogge et al., **The Rise of the Citizen Developer**. IEEE Symposium on Security and Privacy, 2018. <https://doi.org/10.1109/SP.2018.00005>
8. Perry et al., **Do Users Write More Insecure Code with AI Assistants?** ACM CCS 2023. <https://doi.org/10.1145/3576915.3623157>
9. Check Point Research, **Thousands of Open Cloud Databases Exposing Data in the Wild** (March 2022). <https://blog.checkpoint.com/security/stop-neglecting-your-cloud-security-features-check-point-research-found-thousands-of-open-cloud-databases-exposing-data-in-the-wild/>
10. OWASP, **OWASP Top 10**. Risk taxonomy reference. <https://top10.owasp.org/>

> [!NOTE]
> This page was intentionally simplified to be more GitHub-readable. The evidence base is still mixed: some sources are original disclosures, some are observational studies, and some are broad security guidance.

[Full research report](../reports/app_builders_security_research.pdf) · [Published source notes](../research/app-builders/README.md)
