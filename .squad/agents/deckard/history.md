# Deckard — History

## Project Context
- **Project:** AI Gateway Session Builder
- **User:** Kiko de Angel
- **Goal:** Deep research on Azure AI Gateway for session preparation
- **Reference Materials:** 4 PPTXs in preparation folder
- **Key Intel:** New AI Gateway SKU = new APIM SKU with AI gateway + catalog + registry, 1400 MCP connectors, AI-native CLI, OTel tracing

## Learnings

### 2026-05-11T01:58:27Z — Research validated and integrated into team narrative
- Tyrell confirmed session outline is solid based on research findings.
- Pris incorporated research findings into PPTX v2 (36 slides, 808KB).
- Roy built 4-demo sequence on defensible current capabilities (tokens, caching, failover, MCP governance).
- All agents aligned: AI Gateway is APIM-based today; new SKU private preview is closing reveal, not opener.
- Kiko confirmed research brief is accurate for presentation narrative.

### 2026-05-11: Azure AI Gateway research brief delivered
- Public Microsoft position is clear: AI Gateway is an APIM capability set, not a standalone public Azure service today.
- The strongest public architecture story is "Foundry control plane + APIM enforcement plane + API Center registry/catalog".
- Foundry preview can create a Basic v2 APIM instance or attach an existing v2 instance; new projects are gateway-enabled by default.
- Core technical pillars confirmed in public docs: `llm-token-limit`, semantic caching with Redis/RediSearch, `llm-content-safety`, backend pools, circuit breaker, retry, token metrics, MCP governance, and custom agent registration.
- MCP is now a real platform story in Azure: APIM for mediation, API Center for registry/plugin marketplace, Foundry for governed tool consumption.
- Public docs do not yet confirm the rumored standalone/private-preview AI Gateway SKU, dedicated CLI, or the exact "1400 connectors as MCP servers" claim; these should be framed as private-preview/roadmap, not public fact.
- Observability split matters: managed APIM emphasizes Azure Monitor/App Insights, while self-hosted gateway has direct OpenTelemetry metrics export and Foundry custom agents use OTel semantic conventions through App Insights.
