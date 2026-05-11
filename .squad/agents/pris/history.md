# Pris — History

## Project Context
- **Project:** AI Gateway Session Builder
- **User:** Kiko de Angel
- **Goal:** Design stunning PPTX presentation (30-50 slides, English) about Azure AI Gateway
- **Key Reference:** "10- Integration with Azure API Management - AI Gateway.pptx" has particularly good slides
- **Must Include:** New SKU private preview announcement slides

## Learnings

### 2026-05-11T01:58:27Z — PPTX v2 finalized; all team updates integrated
- Research brief (Deckard 756 lines) fully incorporated into slide content.
- Session outline (Tyrell) serves as primary source for all speaker notes.
- Demo plan v2 (Roy) breaks out demo 1-4 into dedicated slides with exact timing.
- Gaff's infrastructure scripts (24 assets) aligned with demo flow.
- All 36 slides verified with markitdown.
- Ocean Gradient palette + dark sandwich structure maintains visual rhythm across all content.
- Next: Final review with Tyrell; speaker notes printed; backup video recording.

### 2026-05-11 — AI Gateway Session Deck (36 slides)

**What worked:**
- PptxGenJS v4 with local npm install — global modules don't resolve in Node.js v24
- Ocean Gradient palette with dark sandwich structure (dark title/section/close, light content) creates strong visual rhythm
- Factory function `shadow()` prevents PptxGenJS object mutation bugs
- Helper functions (addCard, addIconCircle, addStat, addDemoSlide) enforce consistency across 36 slides
- Speaker notes on every slide from session-outline.md

**Key PptxGenJS gotchas:**
- Slide `background` must be `{ color: "xxx" }` — NOT `{ fill: { color: "xxx" } }`
- Colors must be 6-char hex WITHOUT `#` prefix — `"065A82"` not `"#065A82"`
- Never reuse option objects — library mutates them in place
- Use `pres.shapes.RECTANGLE` not `ROUNDED_RECTANGLE` for accent bars

**What I'd improve next time:**
- Pre-render SVG icons as PNGs for richer icon visuals (Unicode emoji/symbols are limited)
- LibreOffice + pdftoppm not available in this environment — need alternative visual QA path
- Could add gradient fills for more visual depth on section openers

### 2026-05-11 — AI Gateway Session Deck v2 (36 slides, with react-icons)

**What worked:**
- react-icons → renderToStaticMarkup → sharp PNG → base64 pipeline gives crisp vector icons
- Card helper with left-side RECTANGLE accent bar provides visual hierarchy without overdesign
- Pillar number pattern (colored squares with white numbers) works well for numbered lists
- Architecture diagrams built from simple RECTANGLE shapes + text are surprisingly readable
- Before/After card layouts (semantic caching slide) are very effective for showing value
- Demo slides with mint accent bar separator and "🔴 LIVE DEMO" label stand out well
- markitdown verification confirmed all 36 slides with correct content and speaker notes

**Key learnings:**
- Install react, react-dom, sharp LOCALLY (not globally) — Node.js v24 doesn't resolve global modules
- react-icons/fa exports work fine with require() in CJS
- EBUSY errors when PPTX is open in PowerPoint — use alternate filename and copy
- cardShadow() factory pattern is essential — PptxGenJS mutates shadow objects
- Comparison tables with colW array give precise column control
- 10-rule "cheat sheet" slide works best as 2-column numbered list layout
