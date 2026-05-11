# Tyrell — History

## Project Context
- **Project:** AI Gateway Session Builder
- **User:** Kiko de Angel
- **Goal:** Build English-language session about Azure AI Gateway (PPTX 30-50 slides + demo)
- **Key Intel:** Jarrod Krige posted Private Preview for new AI Gateway SKU (April 29, 2026) in EMEA Azure AI GPS Chat

## Learnings

### 2026-05-11T01:58:27Z — Team synthesis: All agents completed
- **Deckard delivered:** 756-line research brief. Confirmed AI Gateway is APIM-based today; Foundry is cleanest public on-ramp story.
- **Roy delivered:** 4-demo sequence with v2 refinements (EU regions only, 3 monitoring surfaces for Demo 2, 1 MCP server for Demo 4).
- **Pris delivered:** 36-slide PPTX v2 (808KB) with full research integration, speaker notes, Ocean palette, dark sandwich structure.
- **Gaff delivered:** 24-asset demo infrastructure (provisioning, policies, clients, workbooks); migrated to AI Foundry; awaiting ARM template update (v3).
- **Kiko directive:** All provisioning must use AI Foundry (never standalone Azure OpenAI). User provided production ARM template reference.
- **Next:** Session outline remains solid; all 4 demos are defensible with current product. Private preview as Section 5 closing still lands as bombshell.

### 2026-05-11T00:58:01Z — Session structure defined
- Created full session outline: 6 sections, ~35 slides, ~41 min runtime, 3 demos
- Title: "AI Gateway: The Control Plane Your AI Strategy Is Missing"
- Narrative arc: Problem (governance gap) → Solution (AI Gateway today) → Experience (demos) → Future (new SKU)
- Private preview positioned as closing bombshell (Section 5), not opener — builds on current capabilities for maximum impact
- Three demos distributed across deep-dive: Token Governance, MCP Integration, Semantic Caching
- Audience: platform engineers, cloud architects, AI/ML engineers, IT decision-makers
- Key design decisions documented in .squad/decisions/inbox/tyrell-session-structure.md
- Output: session-outline.md at repo root
