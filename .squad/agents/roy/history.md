# Roy — History

## Project Context
- **Project:** AI Gateway Session Builder
- **User:** Kiko de Angel
- **Goal:** Design compelling demos for AI Gateway session
- **Considerations:** Can a local model be published through AI Gateway? Multi-part demos welcome. Must be achievable with Azure resources.

## Learnings

### 2026-05-11T01:58:27Z — Demo plan v2 finalized; team synthesis complete
- Kiko confirmed v2 plan is actionable for tomorrow. All 4 demos have exact Azure paths and scripts.
- Gaff created 24-asset infrastructure suite with provisioning, policy XML, load test clients, workbook template.
- Tyrell confirmed demo placements align with narrative arc (curiosity peaks after explain→show pattern).
- Pris created 36-slide deck with demo breakpoints and speaker notes.
- Gaff v3 is updating ARM templates to match Kiko's production reference (kind: "AIServices", projects as children, managed identity).
- Pre-provisioning checklist: 27 ordered items across 6 phases. APIM provisioning is bottleneck (~30 min).
- All demos confirmed to use AI Foundry (never standalone Azure OpenAI).

### 2026-05-11: Demo Proposal v1 Delivered
- Designed 4-demo sequence following "Build → Govern → Scale → Extend" arc
- Demos: Zero to AI Platform (5m), Token Police (7m), AI Traffic Controller (8m), MCP Gateway (7m) = ~27 min total
- Key insight: circuit breaker demo needs a mock backend (Azure Function returning 500) rather than disabling real OpenAI — much more reliable for live delivery
- Key insight: MCP features are in early preview; build mock MCP servers as Azure Functions for reliability
- Content safety demo works best when tested with 3-4 known harmful prompt categories beforehand
- Total Azure cost estimate: €65-105/mo, or ~€30-50 for a 2-week prep+delivery window
- Dropped "Local Model Goes Enterprise" idea — technically impressive but too risky for live demo (network tunneling, Ollama setup, audience can't reproduce). Could be a future follow-up.
- Every demo should have a "glass break" fallback (screenshot or recording) — never debug live

### 2026-05-11: Demo Plan v2 — Kiko's Feedback Incorporated
- Kiko accepted all 4 demos with modifications
- Real-time monitoring answer for Demo 2: THREE surfaces — Live Metrics (1-2s), Metrics Explorer (1-3 min), Custom Workbook (30s auto-refresh). The Workbook with KQL queries is the recommended primary visual for live demo.
- Key learning: `azure-openai-emit-token-metric` policy is the critical enabler for token dashboards — without it, App Insights only sees request-level data, not token counts
- Demo 3 updated to all-EU regions: Sweden Central (50%), France Central (30%), North Europe (20%) — Kiko was explicit about no US regions
- Demo 4 simplified from 2 MCP servers to 1 (Product Catalog) — realistic scope for overnight prep. Scripted curl calls instead of live agent. REST-to-MCP conversion deferred to slide.
- Pre-provisioning takes 2-3 hours including testing. APIM provisioning (15-30 min) is the bottleneck — start it first.
- Policy injection plan created: 5 policies total, each with full XML ready for Gaff to wrap in Azure CLI scripts
- Mock "kill switch" Azure Function is more reliable than disabling real Azure OpenAI deployment for circuit breaker demo
