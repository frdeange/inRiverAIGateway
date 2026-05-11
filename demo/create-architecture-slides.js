/**
 * Creates architecture slides for Hybrid AI Gateway with Local Model Routing
 * Ocean Gradient theme - Dark background professional style
 */

const pptxgen = require("pptxgenjs");

// Ocean Gradient Color Palette
const COLORS = {
  primary: "065A82",       // Deep blue
  secondary: "1C7293",     // Teal  
  accent: "02C39A",        // Mint green
  dark: "21295C",          // Midnight
  background: "0B132B",    // Dark navy background
  text: "FFFFFF",          // White text
  textMuted: "A0B0C0",     // Muted text
  cardBg: "1A2744",        // Card background (slightly lighter than bg)
  onPrem: "02C39A",        // Mint for on-prem path
  cloud: "1C7293",         // Teal for cloud path
  gateway: "065A82"        // Deep blue for gateway
};

// Helper to create shadow (fresh object each time)
const makeShadow = () => ({
  type: "outer",
  color: "000000",
  blur: 4,
  offset: 2,
  angle: 135,
  opacity: 0.3
});

// Helper to create component card
function addComponentCard(slide, pres, x, y, w, h, label, emoji, fillColor, options = {}) {
  // Card background
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x, y, w, h,
    fill: { color: fillColor || COLORS.cardBg },
    line: { color: options.borderColor || COLORS.secondary, width: 1.5 },
    rectRadius: 0.15,
    shadow: makeShadow()
  });

  // Emoji icon circle (if emoji provided)
  if (emoji) {
    const emojiY = y + 0.15;
    slide.addShape(pres.shapes.OVAL, {
      x: x + w/2 - 0.25, y: emojiY, w: 0.5, h: 0.5,
      fill: { color: options.iconBg || COLORS.dark },
      line: { color: options.borderColor || COLORS.secondary, width: 1 }
    });
    slide.addText(emoji, {
      x: x + w/2 - 0.25, y: emojiY, w: 0.5, h: 0.5,
      fontSize: 14, align: "center", valign: "middle"
    });
  }

  // Label text
  const labelY = emoji ? y + h/2 + 0.1 : y;
  slide.addText(label, {
    x: x + 0.1, y: labelY, w: w - 0.2, h: emoji ? h/2 - 0.1 : h,
    fontSize: options.fontSize || 10,
    fontFace: "Calibri",
    color: COLORS.text,
    align: "center",
    valign: emoji ? "top" : "middle",
    bold: options.bold !== false
  });
}

// Helper to draw arrow line
function addArrow(slide, pres, x1, y1, x2, y2, color, options = {}) {
  const w = x2 - x1;
  const h = y2 - y1;
  slide.addShape(pres.shapes.LINE, {
    x: x1, y: y1, w: w, h: h,
    line: { 
      color: color || COLORS.accent, 
      width: options.width || 2,
      endArrowType: options.noArrow ? null : "triangle",
      dashType: options.dashed ? "dash" : "solid"
    }
  });
}

// Helper to add region badge
function addRegionBadge(slide, pres, x, y, label, color) {
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x, y, w: 0.9, h: 0.35,
    fill: { color: color },
    rectRadius: 0.08
  });
  slide.addText(label, {
    x, y, w: 0.9, h: 0.35,
    fontSize: 8, fontFace: "Calibri", color: COLORS.text,
    align: "center", valign: "middle", bold: true
  });
}

function createSlide1(pres) {
  const slide = pres.addSlide();
  slide.background = { color: COLORS.background };

  // Title
  slide.addText("Hybrid AI Gateway — Any Model, Anywhere", {
    x: 0.5, y: 0.25, w: 9, h: 0.6,
    fontSize: 28, fontFace: "Arial Black", color: COLORS.text, bold: true
  });

  // Subtitle
  slide.addText("One gateway governs cloud AND on-prem models", {
    x: 0.5, y: 0.85, w: 9, h: 0.35,
    fontSize: 14, fontFace: "Calibri", color: COLORS.accent, italic: true
  });

  // === LEFT SIDE: On-Premises Section ===
  // Section label
  slide.addText("ON-PREMISES", {
    x: 0.3, y: 1.35, w: 2.5, h: 0.3,
    fontSize: 10, fontFace: "Calibri", color: COLORS.onPrem, bold: true
  });

  // Laptop
  addComponentCard(slide, pres, 0.3, 1.7, 1.4, 0.9, "Workstation\nRTX 4050", "💻", COLORS.cardBg, {
    borderColor: COLORS.onPrem, iconBg: COLORS.onPrem
  });

  // Arrow laptop -> Ollama
  addArrow(slide, pres, 1.0, 2.6, 1.0, 2.85, COLORS.onPrem);

  // Ollama
  addComponentCard(slide, pres, 0.3, 2.9, 1.4, 0.8, "Ollama\nphi4-mini", "🤖", COLORS.cardBg, {
    borderColor: COLORS.onPrem, iconBg: COLORS.onPrem
  });

  // Arrow Ollama -> DevTunnel
  addArrow(slide, pres, 1.0, 3.7, 1.0, 3.95, COLORS.onPrem);

  // DevTunnel
  addComponentCard(slide, pres, 0.3, 4.0, 1.4, 0.7, "DevTunnel", "🔗", COLORS.cardBg, {
    borderColor: COLORS.onPrem, iconBg: COLORS.onPrem
  });

  // Arrow DevTunnel -> Gateway (horizontal)
  addArrow(slide, pres, 1.7, 4.35, 3.1, 4.35, COLORS.onPrem);

  // === CENTER: Azure AI Gateway ===
  // Large gateway box
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 3.1, y: 1.7, w: 3.8, h: 3.6,
    fill: { color: COLORS.dark },
    line: { color: COLORS.gateway, width: 3 },
    rectRadius: 0.2,
    shadow: makeShadow()
  });

  // Gateway header
  slide.addText("Azure AI Gateway (APIM)", {
    x: 3.2, y: 1.85, w: 3.6, h: 0.4,
    fontSize: 14, fontFace: "Arial Black", color: COLORS.text, align: "center", bold: true
  });

  // Control plane label
  slide.addText("Control Plane", {
    x: 3.2, y: 2.25, w: 3.6, h: 0.3,
    fontSize: 10, fontFace: "Calibri", color: COLORS.textMuted, align: "center"
  });

  // Policy cards inside gateway
  const policies = [
    { label: "Rate Limiting", emoji: "⏱️" },
    { label: "Content Safety", emoji: "🛡️" },
    { label: "Logging & Metrics", emoji: "📊" },
    { label: "Token Tracking", emoji: "🔢" }
  ];

  policies.forEach((p, i) => {
    const col = i % 2;
    const row = Math.floor(i / 2);
    const px = 3.3 + col * 1.75;
    const py = 2.7 + row * 1.1;
    
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x: px, y: py, w: 1.55, h: 0.9,
      fill: { color: COLORS.cardBg },
      line: { color: COLORS.secondary, width: 1 },
      rectRadius: 0.1
    });
    slide.addText(p.emoji, {
      x: px, y: py + 0.1, w: 1.55, h: 0.35,
      fontSize: 16, align: "center", valign: "middle"
    });
    slide.addText(p.label, {
      x: px + 0.05, y: py + 0.5, w: 1.45, h: 0.35,
      fontSize: 9, fontFace: "Calibri", color: COLORS.text, align: "center", valign: "middle"
    });
  });

  // === RIGHT SIDE: Cloud Section ===
  // Section label
  slide.addText("AZURE AI FOUNDRY", {
    x: 7.1, y: 1.35, w: 2.6, h: 0.3,
    fontSize: 10, fontFace: "Calibri", color: COLORS.cloud, bold: true
  });

  // Cloud box
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 7.1, y: 1.7, w: 2.6, h: 2.3,
    fill: { color: COLORS.cardBg },
    line: { color: COLORS.cloud, width: 2 },
    rectRadius: 0.15,
    shadow: makeShadow()
  });

  // Cloud icon
  slide.addText("☁️", {
    x: 7.1, y: 1.85, w: 2.6, h: 0.5,
    fontSize: 24, align: "center", valign: "middle"
  });

  // 3 Regions
  addRegionBadge(slide, pres, 7.25, 2.5, "Sweden", COLORS.secondary);
  addRegionBadge(slide, pres, 8.25, 2.5, "France", COLORS.secondary);
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 7.75, y: 2.95, w: 0.9, h: 0.35,
    fill: { color: COLORS.secondary },
    rectRadius: 0.08
  });
  slide.addText("Spain", {
    x: 7.75, y: 2.95, w: 0.9, h: 0.35,
    fontSize: 8, fontFace: "Calibri", color: COLORS.text,
    align: "center", valign: "middle", bold: true
  });

  // Multi-region label
  slide.addText("Multi-Region LLM", {
    x: 7.1, y: 3.45, w: 2.6, h: 0.3,
    fontSize: 9, fontFace: "Calibri", color: COLORS.textMuted, align: "center"
  });

  // Arrow Gateway -> Cloud
  addArrow(slide, pres, 6.9, 2.85, 7.1, 2.85, COLORS.cloud);

  // === BOTTOM: Clients ===
  slide.addText("CLIENTS", {
    x: 3.1, y: 5.0, w: 3.8, h: 0.25,
    fontSize: 10, fontFace: "Calibri", color: COLORS.textMuted, align: "center"
  });

  const clients = ["good-app", "rogue-app", "load-test", "local-model"];
  clients.forEach((c, i) => {
    const cx = 3.2 + i * 0.92;
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x: cx, y: 5.25, w: 0.85, h: 0.3,
      fill: { color: i === 1 ? "8B0000" : COLORS.cardBg },  // Red for rogue
      line: { color: i === 1 ? "FF4444" : COLORS.secondary, width: 1 },
      rectRadius: 0.05
    });
    slide.addText(c, {
      x: cx, y: 5.25, w: 0.85, h: 0.3,
      fontSize: 7, fontFace: "Calibri", color: COLORS.text, align: "center", valign: "middle"
    });
  });

  // Arrow from clients to gateway
  slide.addShape(pres.shapes.LINE, {
    x: 5.0, y: 5.25, w: 0, h: -0.15,
    line: { color: COLORS.secondary, width: 2, endArrowType: "triangle" }
  });
}

function createSlide2(pres) {
  const slide = pres.addSlide();
  slide.background = { color: COLORS.background };

  // Title
  slide.addText("How It Works — Local Model Routing", {
    x: 0.5, y: 0.25, w: 9, h: 0.6,
    fontSize: 28, fontFace: "Arial Black", color: COLORS.text, bold: true
  });

  // Flow diagram - horizontal sequence
  const steps = [
    { num: "1", label: "Client Request", sublabel: 'x-model-target: local', color: COLORS.textMuted },
    { num: "2", label: "AI Gateway", sublabel: "Evaluate Routing Policy", color: COLORS.gateway },
    { num: "3", label: "Route Decision", sublabel: "local OR cloud?", color: COLORS.secondary },
    { num: "4a", label: "DevTunnel", sublabel: "→ Ollama", color: COLORS.onPrem },
    { num: "4b", label: "Azure Foundry", sublabel: "Sweden/France/Spain", color: COLORS.cloud }
  ];

  // Main flow (steps 1-3) - horizontal
  const startY = 1.3;
  const boxW = 2.0;
  const boxH = 1.0;
  const gap = 0.5;

  for (let i = 0; i < 3; i++) {
    const step = steps[i];
    const x = 0.5 + i * (boxW + gap);
    
    // Step number circle
    slide.addShape(pres.shapes.OVAL, {
      x: x + boxW/2 - 0.2, y: startY - 0.3, w: 0.4, h: 0.4,
      fill: { color: step.color },
      line: { color: COLORS.text, width: 1 }
    });
    slide.addText(step.num, {
      x: x + boxW/2 - 0.2, y: startY - 0.3, w: 0.4, h: 0.4,
      fontSize: 12, fontFace: "Arial Black", color: COLORS.text, align: "center", valign: "middle"
    });

    // Box
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x, y: startY, w: boxW, h: boxH,
      fill: { color: COLORS.cardBg },
      line: { color: step.color, width: 2 },
      rectRadius: 0.1,
      shadow: makeShadow()
    });

    // Label
    slide.addText(step.label, {
      x, y: startY + 0.15, w: boxW, h: 0.4,
      fontSize: 12, fontFace: "Calibri", color: COLORS.text, align: "center", valign: "middle", bold: true
    });
    slide.addText(step.sublabel, {
      x, y: startY + 0.5, w: boxW, h: 0.4,
      fontSize: 9, fontFace: "Calibri", color: COLORS.textMuted, align: "center", valign: "middle"
    });

    // Arrow to next (except last)
    if (i < 2) {
      addArrow(slide, pres, x + boxW, startY + boxH/2, x + boxW + gap, startY + boxH/2, COLORS.secondary);
    }
  }

  // Decision diamond area (after step 3)
  const decisionX = 6.5;
  const decisionY = startY + boxH/2;

  // Arrow from step 3 down
  slide.addShape(pres.shapes.LINE, {
    x: 5.75, y: startY + boxH, w: 0, h: 0.4,
    line: { color: COLORS.secondary, width: 2 }
  });

  // === Branch paths ===
  const branchY = 2.8;
  
  // Local path (left branch) - Step 4a
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 1.5, y: branchY, w: 2.5, h: 1.2,
    fill: { color: COLORS.cardBg },
    line: { color: COLORS.onPrem, width: 2 },
    rectRadius: 0.1,
    shadow: makeShadow()
  });
  slide.addShape(pres.shapes.OVAL, {
    x: 2.55, y: branchY - 0.25, w: 0.4, h: 0.4,
    fill: { color: COLORS.onPrem }
  });
  slide.addText("4a", {
    x: 2.55, y: branchY - 0.25, w: 0.4, h: 0.4,
    fontSize: 11, fontFace: "Arial Black", color: COLORS.text, align: "center", valign: "middle"
  });
  slide.addText("LOCAL PATH", {
    x: 1.5, y: branchY + 0.15, w: 2.5, h: 0.3,
    fontSize: 11, fontFace: "Calibri", color: COLORS.onPrem, align: "center", bold: true
  });
  slide.addText("DevTunnel → Ollama", {
    x: 1.5, y: branchY + 0.45, w: 2.5, h: 0.3,
    fontSize: 10, fontFace: "Calibri", color: COLORS.text, align: "center"
  });
  slide.addText("x-backend-region: on-premises", {
    x: 1.5, y: branchY + 0.8, w: 2.5, h: 0.25,
    fontSize: 8, fontFace: "Calibri", color: COLORS.textMuted, align: "center", italic: true
  });

  // Arrow from decision to local
  slide.addShape(pres.shapes.LINE, {
    x: 4.5, y: 2.5, w: -1.5, h: 0.5,
    line: { color: COLORS.onPrem, width: 2, endArrowType: "triangle" }
  });
  slide.addText("if local", {
    x: 3.4, y: 2.35, w: 1.0, h: 0.25,
    fontSize: 9, fontFace: "Calibri", color: COLORS.onPrem, italic: true
  });

  // Cloud path (right branch) - Step 4b
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 6.0, y: branchY, w: 2.5, h: 1.2,
    fill: { color: COLORS.cardBg },
    line: { color: COLORS.cloud, width: 2 },
    rectRadius: 0.1,
    shadow: makeShadow()
  });
  slide.addShape(pres.shapes.OVAL, {
    x: 7.05, y: branchY - 0.25, w: 0.4, h: 0.4,
    fill: { color: COLORS.cloud }
  });
  slide.addText("4b", {
    x: 7.05, y: branchY - 0.25, w: 0.4, h: 0.4,
    fontSize: 11, fontFace: "Arial Black", color: COLORS.text, align: "center", valign: "middle"
  });
  slide.addText("CLOUD PATH", {
    x: 6.0, y: branchY + 0.15, w: 2.5, h: 0.3,
    fontSize: 11, fontFace: "Calibri", color: COLORS.cloud, align: "center", bold: true
  });
  slide.addText("Azure AI Foundry", {
    x: 6.0, y: branchY + 0.45, w: 2.5, h: 0.3,
    fontSize: 10, fontFace: "Calibri", color: COLORS.text, align: "center"
  });
  slide.addText("x-backend-region: swedencentral", {
    x: 6.0, y: branchY + 0.8, w: 2.5, h: 0.25,
    fontSize: 8, fontFace: "Calibri", color: COLORS.textMuted, align: "center", italic: true
  });

  // Arrow from decision to cloud
  slide.addShape(pres.shapes.LINE, {
    x: 5.75, y: 2.5, w: 1.0, h: 0.5,
    line: { color: COLORS.cloud, width: 2, endArrowType: "triangle" }
  });
  slide.addText("if cloud", {
    x: 6.0, y: 2.35, w: 1.0, h: 0.25,
    fontSize: 9, fontFace: "Calibri", color: COLORS.cloud, italic: true
  });

  // Step 5 - Response flows back
  const step5Y = 4.25;
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 3.5, y: step5Y, w: 3.0, h: 0.85,
    fill: { color: COLORS.cardBg },
    line: { color: COLORS.accent, width: 2 },
    rectRadius: 0.1,
    shadow: makeShadow()
  });
  slide.addShape(pres.shapes.OVAL, {
    x: 4.8, y: step5Y - 0.25, w: 0.4, h: 0.4,
    fill: { color: COLORS.accent }
  });
  slide.addText("5", {
    x: 4.8, y: step5Y - 0.25, w: 0.4, h: 0.4,
    fontSize: 12, fontFace: "Arial Black", color: COLORS.text, align: "center", valign: "middle"
  });
  slide.addText("Response Returns", {
    x: 3.5, y: step5Y + 0.15, w: 3.0, h: 0.35,
    fontSize: 12, fontFace: "Calibri", color: COLORS.text, align: "center", bold: true
  });
  slide.addText("with region header", {
    x: 3.5, y: step5Y + 0.45, w: 3.0, h: 0.3,
    fontSize: 9, fontFace: "Calibri", color: COLORS.textMuted, align: "center"
  });

  // Arrows from both paths to step 5
  slide.addShape(pres.shapes.LINE, {
    x: 2.75, y: branchY + 1.2, w: 1.5, h: 0.55,
    line: { color: COLORS.onPrem, width: 2, endArrowType: "triangle", dashType: "dash" }
  });
  slide.addShape(pres.shapes.LINE, {
    x: 7.25, y: branchY + 1.2, w: -1.5, h: 0.55,
    line: { color: COLORS.cloud, width: 2, endArrowType: "triangle", dashType: "dash" }
  });

  // URLs section at bottom
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.5, y: 5.1, w: 9.0, h: 0.45,
    fill: { color: COLORS.dark },
    line: { color: COLORS.secondary, width: 1 },
    rectRadius: 0.08
  });
  slide.addText([
    { text: "Gateway: ", options: { bold: true, color: COLORS.textMuted } },
    { text: "demoenv-apim.azure-api.net/ollama   ", options: { color: COLORS.text } },
    { text: "DevTunnel: ", options: { bold: true, color: COLORS.textMuted } },
    { text: "299hwf0x-11434.uks1.devtunnels.ms", options: { color: COLORS.onPrem } }
  ], {
    x: 0.6, y: 5.1, w: 8.8, h: 0.45,
    fontSize: 9, fontFace: "Calibri", align: "center", valign: "middle"
  });
}

async function main() {
  const pres = new pptxgen();
  
  pres.layout = "LAYOUT_16x9";
  pres.title = "Hybrid AI Gateway Architecture";
  pres.author = "inRiver AI Gateway Demo";
  pres.subject = "Local Model Routing via Azure APIM";
  
  // Create slides
  createSlide1(pres);
  createSlide2(pres);
  
  // Save
  const outputPath = "C:\\repos\\inRiverAIGateway\\demo\\local-model-architecture.pptx";
  await pres.writeFile({ fileName: outputPath });
  console.log(`✅ Created: ${outputPath}`);
}

main().catch(err => {
  console.error("Error creating presentation:", err);
  process.exit(1);
});
