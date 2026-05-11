# Gaff — History

## Project Context
- **Project:** AI Gateway Session Builder
- **User:** Kiko de Angel
- **Goal:** Implement demos designed by Roy for AI Gateway session
- **Tech:** Azure APIM, Azure OpenAI, Foundry, Bicep/Terraform, Python/Node.js

## Learnings
- 2026-05-11T01:58:27Z — Team synthesis: All demo infrastructure delivered. 24 assets ready. Gaff v3 is updating ARM templates to match Kiko's production reference (kind: "AIServices", projects as children, managed identity). User confirmed AI Foundry mandatory. Production ARM template provided as authoritative reference.
- 2026-05-11T01:53:54.450+02:00 — For tomorrow's reliability, provisioning should attempt Foundry model deployment via CLI but include explicit portal fallback steps when tenant/preview capabilities differ.
- 2026-05-11T01:53:54.450+02:00 — Demo provisioning baseline must use Microsoft AI Foundry Hub/Projects (EU regions) and avoid `az cognitiveservices ... --kind OpenAI` standalone resources.
- 2026-05-11T01:46:23.418+02:00 — Provisioning scripts should emit a ready-to-edit `.env` with Azure OpenAI endpoints/keys plus APIM placeholders so demo clients can run immediately after manual APIM creation.
- 2026-05-11T01:46:23.418+02:00 — For live AI Gateway demos, keep policies as separate XML files and inject one at a time because APIM supports a single policy document per scope.
