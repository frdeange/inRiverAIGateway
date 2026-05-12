# 🎯 AI Gateway Demo — Runbook (Current State)

> Last synced with deployed demo APIs: **2026-05-12**

---

## 📁 Demo Layout

```text
src/
├── demo1/  — Geographic Load Balancing
│   ├── good-app.py      — Single request, shows region
│   ├── rogue-app.py     — 20 fast requests, shows rate limiting
│   ├── load-test.py     — 20 parallel requests, shows region distribution
│   └── local-model.py   — Routes to local Ollama model
├── demo2/  — Smart Product-Based Routing
│   ├── smart-app.py       — 3 tiers, shows model override
│   └── smart-load-test.py — Load test per tier with region distribution
├── demo3/  — Noisy Neighbor Protection
│   ├── rate-limit-demo.py  — Calls/min rate limiting (429)
│   ├── quota-demo.py       — Monthly token quota (403)
│   └── noisy-neighbor.py   — Combined demo (legacy)
├── demo4/  — Enterprise JWT + Credit Service
│   ├── enterprise-app.py   — JWT auth + external credit check
│   ├── generate-token.py   — JWT token generator
│   └── credit-service/     — FastAPI credit service (ACA)
└── apim-policies/
    ├── load-balancer-pool.xml
    ├── smart-routing.xml
    ├── rate-limit.xml
    ├── token-quota.xml
    └── enterprise-jwt-credits.xml
```

---

## ☁️ Azure Resources Needed

| Resource | Why it is needed |
|---|---|
| APIM instance | Hosts `/ai`, `/smartai`, `/noisyneighbor`, `/noisy-neighbor2`, `/inrivermock` |
| APIM backend pool `OpenAI-Balanced` | Geographic cloud routing for Demo 1/2/4 |
| APIM backend `localollama-openai-endpoint` | Developer-tier local model routing for Demo 2 |
| Azure OpenAI/Foundry deployments | Cloud models (`gpt-5.2`, `gpt-4.1`) |
| ACA credit service | Tenant credit checks for Demo 4 |
| Managed identity on APIM | Auth to Azure OpenAI without API keys |
| App Insights (optional) | Live traces during demos |

---

## ⚙️ Environment Variables (`.env`)

Create from template:

```powershell
cd C:\repos\inRiverAIGateway\src
Copy-Item .env.example .env
```

> Do **not** put real values in docs; use placeholders from `src/.env.example`.

| Variable | Used by |
|---|---|
| `FOUNDRY_SEC_ENDPOINT`, `FOUNDRY_FRC_ENDPOINT`, `FOUNDRY_ESP_ENDPOINT` | demo1 / direct mode checks |
| `MODEL_DEPLOYMENT`, `API_VERSION` | all OpenAI client scripts |
| `AI_GATEWAY_URL`, `AI_GATEWAY_KEY` | all APIM-governed demos |
| `LOCAL_MODEL_URL`, `LOCAL_MODEL_NAME` | demo1 bonus local model |
| `REQUESTS_PER_TIER`, `SMARTAI_*` | demo2 tier routing/load test |
| `NOISY_CUSTOMER_A_*`, `NOISY_CUSTOMER_B_*` | demo3 fairness demos |
| `JWT_SECRET`, `CREDIT_SERVICE_URL` | demo4 JWT + credits |
| `APPINSIGHTS_NAME`, `RESOURCE_GROUP`, `APIM_NAME`, `MCP_SERVER_URL` | infra helpers |

---

## 🎬 Demo 1 — Geographic Load Balancing

**What it demonstrates:** Cloud traffic goes through APIM to the balanced backend pool with managed identity. You can show single-call, burst, and parallel distribution behavior.

- **APIM API:** `/ai`
- **Policy:** `apim-policies/load-balancer-pool.xml`

### Run

```powershell
cd C:\repos\inRiverAIGateway\src
python .\demo1\good-app.py
python .\demo1\rogue-app.py
python .\demo1\load-test.py
```

### Expected output

- `good-app.py`: 200 response, model answer, and region headers.
- `rogue-app.py`: initial 200s, then `RATE-LIMITED (429)`.
- `load-test.py`: summary with backend/region distribution.

---

## 🎬 Demo 2 — Smart Product-Based Routing

**What it demonstrates:** APIM routes by product and rewrites model/URI. Premium uses `gpt-5.2`, Economy uses `gpt-4.1`, Developer goes to local `phi4-mini`.

- **APIM API:** `/smartai`
- **Policy:** `apim-policies/smart-routing.xml`

### Run

```powershell
cd C:\repos\inRiverAIGateway\src
python .\demo2\smart-app.py
python .\demo2\smart-load-test.py
```

### Expected output

- `x-model-tier` reflects premium/economy/developer.
- `response.model` differs per tier.
- developer tier may show `on-premises` / local behavior.

---

## 🎬 Demo 3a — Noisy Neighbor (Rate Limit)

**What it demonstrates:** Hard request-rate fairness (3 calls/min) per subscription.

- **APIM API:** `/noisyneighbor`
- **Policy:** `apim-policies/rate-limit.xml`

### Run

```powershell
cd C:\repos\inRiverAIGateway\src
python .\demo3\rate-limit-demo.py
```

### Expected output

- One customer can flood and get 429.
- Other customer remains mostly unaffected.

---

## 🎬 Demo 3b — Noisy Neighbor (Monthly Token Quota)

**What it demonstrates:** Monthly token budgeting per subscription using LLM token-limit.

- **APIM API:** `/noisy-neighbor2`
- **Policy:** `apim-policies/token-quota.xml`

### Run

```powershell
cd C:\repos\inRiverAIGateway\src
python .\demo3\quota-demo.py
```

### Expected output

- Quota headers decrease over calls.
- `403 QUOTA EXCEEDED` once monthly budget is consumed.

---

## 🎬 Demo 4 — Enterprise JWT + Credit Service

**What it demonstrates:** Inbound enterprise controls with JWT validation + tenant credit check before model forwarding.

- **APIM API:** `/inrivermock`
- **Policy:** `apim-policies/enterprise-jwt-credits.xml`

### Run

```powershell
cd C:\repos\inRiverAIGateway\src
python .\demo4\generate-token.py --tenant tenant-adidas --user user1@adidas.com
python .\demo4\enterprise-app.py
```

### Expected output

- Valid tenant with credits: normal model response + `x-remaining-credits` header.
- Tenant without credits: `403 Credit quota exceeded`.

---

## ➕ Bonus — Local Model via DevTunnel / Ollama

**What it demonstrates:** Same client can run direct-to-local or through APIM passthrough.

- **APIM API (optional):** `/ollama`
- **Policy:** passthrough API configuration (no dedicated XML in current set)

### Run

```powershell
cd C:\repos\inRiverAIGateway\src
python .\demo1\local-model.py
```

### Expected output

- Direct mode: `🏠 Mode: Local Model (direct)`
- Governed mode: `🔒 Mode: AI Gateway → Local Model (governed)`

---

## 💉 Applying Policies Manually

Use APIM policy editor and paste from `src/apim-policies/` files above to each API path.