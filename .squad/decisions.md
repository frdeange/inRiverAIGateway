# Squad Decisions

### 2026-05-11T00:53:00Z: Project kickoff
**By:** Kiko de Angel
**What:** Build an English-language AI Gateway session with PPTX (30-50 slides) and live demo. Include new SKU private preview info from Jarrod Krige (April 29, 2026 — EMEA Azure AI GPS Chat).
**Why:** Preparation for AI Gateway presentation/session delivery.

### 2026-05-11T00:53:00Z: Model assignments
**By:** Squad (Coordinator)
**What:** Premium models (claude-opus-4.6) for Tyrell, Pris, Roy. Code specialist (gpt-5.3-codex) for Gaff. Standard (claude-sonnet-4.6) for Deckard.
**Why:** Presentation design and demo architecture need maximum quality; code needs specialist model.

### 2026-05-11T00:53:00Z: Reference materials
**By:** Squad (Coordinator)
**What:** 4 reference PPTXs available in C:\Users\frdeange\OneDrive - Microsoft\00.- Tareas Pendientes\InRiver\AIGateway\Preparación. Key deck: "10- Integration with Azure API Management - AI Gateway.pptx".
**Why:** Source material for presentation content and inspiration.

### 2026-05-11T00:58:01Z: Session title and tagline
**By:** Tyrell (Lead / Content Strategist)
**What:** Title: "AI Gateway: The Control Plane Your AI Strategy Is Missing" — Tagline: "From chaos to control — govern models, tools, and agents at enterprise scale with Azure API Management."
**Why:** Positions AI Gateway as essential infrastructure. "Control plane" resonates with platform engineers. "Missing" creates urgency.

### 2026-05-11T00:58:01Z: Narrative arc — 4-act structure
**By:** Tyrell (Lead / Content Strategist)
**What:** Act 1: The Problem (governance gap), Act 2: The Solution (AI Gateway today), Act 3: The Experience (demos), Act 4: The Future (new SKU private preview). Closing CTA.
**Why:** Progressive disclosure keeps audience engaged. Leading with pain establishes relevance before solution. Private preview as climax.

### 2026-05-11T00:58:01Z: ~35 slides, ~41 min runtime
**By:** Tyrell (Lead / Content Strategist)
**What:** 6 sections, ~35 slides total, ~41 min including 3 demos (~10-12 min demo time). Fits 45-min slot with tight transitions or 60-min with Q&A buffer.
**Why:** Within 30-50 slide brief. Adequate depth on core capabilities and private preview without bloat.

### 2026-05-11T00:58:01Z: Three demos placed at curiosity peaks
**By:** Tyrell (Lead / Content Strategist)
**What:** Demo 1: Token Governance (after cost control slides). Demo 2: MCP Integration (after MCP explanation). Demo 3: Semantic Caching (after advanced patterns). Each demo 2-5 min.
**Why:** Demos follow explain→show pattern at moments where audience understands WHAT but wants to see HOW.

### 2026-05-11T00:58:01Z: Private preview as closing bombshell, not opener
**By:** Tyrell (Lead / Content Strategist)
**What:** New AI Gateway SKU private preview revealed in Section 5 (slides 27-32), after all current capabilities and demos. Transition: "Everything you've seen is available today. But we're just getting started."
**Why:** Present capabilities feel impressive. Future reveal then lands as "AND there's more?" — more powerful than leading with futures.

### 2026-05-11T00:58:01Z: Demo ground rules
**By:** Tyrell (Lead / Content Strategist)
**What:** Each demo self-contained, visible wow moment, ends on slide. Pre-recorded backup for each demo. Total demo time capped at 12 min.
**Why:** Live demos fail. Backup videos are insurance. Self-contained demos survive attention lapses. Returning to slides maintains narrative control.

### 2026-05-11T01:46:23Z: Demo infrastructure scripts delivered
**By:** Gaff
**What:** Added end-to-end demo assets under `demo/`: Azure provisioning script, APIM policy XML library, policy injection script, Good/Rogue/load-test clients, optional mock MCP Azure Functions, workbook template.
**Why:** Live session needs pre-provisioned EU resources, fast policy toggles, deterministic client behavior, real-time observability.

### 2026-05-11T01:46:23Z: Demo Plan v2 — Updated After Kiko's Feedback
**By:** Roy (Demo Architect)
**What:** Updated demos: Demo 2 monitoring (Live Metrics, Metrics Explorer, Custom Workbook with KQL queries). Demo 3 regions changed to EU only (Sweden Central 50%, France Central 30%, North Europe 20%). Demo 4 scope reduced to 1 MCP server + scripted curl. Pre-provisioning checklist: 27 items, 2-3 hours total.
**Why:** Session is tomorrow. Kiko needs pre-provisioned resources and policy scripts ready. v1 was conceptual; v2 is actionable with exact Azure paths and resource names.

### 2026-05-11T01:53:54Z: User directive — AI Foundry architecture
**By:** Kiko de Angel (via Copilot)
**What:** Always create AI Foundry resources, never standalone Azure OpenAI. Models deployed through Foundry projects, not individual Cognitive Services accounts.
**Why:** User request — AI Foundry is current standard. Azure OpenAI standalone is legacy.

### 2026-05-11T01:53:54Z: Migrated demo provisioning to AI Foundry
**By:** Gaff
**What:** Rewrote `demo/provision-resources.ps1` to provision AI Foundry Hub + Projects (Sweden Central, France Central, North Europe), emit Foundry endpoints/keys to `.env`, attempt GPT-4o deployment with resilient CLI-first + portal fallback.
**Why:** Kiko mandated AI Foundry architecture. Updated APIM/demo assets to Foundry backend model, load-balancer policies, inject-policies.ps1 with backend-id replacement, demo clients for base-url/route/api-version composition.

### 2026-05-11T01:58:27Z: AI Foundry ARM template reference
**By:** Kiko de Angel
**What:** Correct ARM template structure: `Microsoft.CognitiveServices/accounts` with `kind: "AIServices"` (NOT `kind: "OpenAI"`), `allowProjectManagement: true`, `defaultProject` property, Projects and Model Deployments as child resources, Connections and RAI policies as child resources, API version `2025-10-01-preview`, `disableLocalAuth: true` (Entra ID only), System-assigned Managed Identity on account and project.
**Why:** Real-world production ARM template from inRiver project — authoritative reference for provisioning scripts.

### 2026-05-11T01:58:27Z: Deckard research findings complete
**By:** Deckard (Researcher)
**What:** Research brief delivered covering architecture, SKU model, token governance, semantic caching, content safety, load balancing, MCP support, Foundry integration, observability, security, competitive landscape, and customer scenarios. Key finding: AI Gateway is APIM-based today; Foundry is cleanest public story for on-ramp.
**Why:** Session narrative confirmed. Tyrell can present current product truth without over-claiming. Pris can visualize control plane vs enforcement plane. Roy can build defensible demos on token limits, caching, failover, MCP governance.
