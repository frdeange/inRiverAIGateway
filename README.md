# 🤖 inRiver AI Gateway Demo Kit

> **Current demo set:** Geographic load balancing, smart product routing, noisy-neighbor protection, and enterprise JWT + credit checks.

[![Azure Samples](https://img.shields.io/badge/Azure-Samples-0078D4?style=flat-square&logo=microsoft-azure)](https://github.com/Azure-Samples/AI-Gateway)
[![Python 3.11+](https://img.shields.io/badge/Python-3.11+-3776ab?style=flat-square&logo=python)](https://www.python.org/)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-5391FE?style=flat-square&logo=powershell)](https://learn.microsoft.com/en-us/powershell/)

---

## 📁 Current Demo Structure

```text
src/
├── demo1/  — Geographic Load Balancing
│   ├── good-app.py
│   ├── rogue-app.py
│   ├── load-test.py
│   └── local-model.py
├── demo2/  — Smart Product-Based Routing
│   ├── smart-app.py
│   └── smart-load-test.py
├── demo3/  — Noisy Neighbor Protection
│   ├── rate-limit-demo.py
│   ├── quota-demo.py
│   └── noisy-neighbor.py
├── demo4/  — Enterprise JWT + Credit Service
│   ├── enterprise-app.py
│   ├── generate-token.py
│   └── credit-service/
└── apim-policies/
    ├── load-balancer-pool.xml
    ├── smart-routing.xml
    ├── rate-limit.xml
    ├── token-quota.xml
    └── enterprise-jwt-credits.xml
```

---

## ☁️ Azure Resources Needed

- 🏛️ Azure API Management instance (with APIs `/ai`, `/smartai`, `/noisyneighbor`, `/noisy-neighbor2`, `/inrivermock`)
- 🤖 Azure OpenAI / Foundry backends (regional + balanced backend pool `OpenAI-Balanced`)
- 🐳 Azure Container Apps credit service (Demo 4)
- 🔐 Managed identity enabled on APIM for OpenAI calls
- 📊 Application Insights (optional but recommended for live demo telemetry)

---

## ⚙️ Environment Variables (`src/.env`)

Copy from template:

```powershell
cd src
Copy-Item .env.example .env
```

> Use `src/.env.example` for variable names and placeholder values.

| Variable | Description |
|---|---|
| `FOUNDRY_SEC_ENDPOINT`, `FOUNDRY_FRC_ENDPOINT`, `FOUNDRY_ESP_ENDPOINT` | Regional OpenAI endpoints used by direct mode and validation scripts |
| `MODEL_DEPLOYMENT` | Default cloud model deployment (usually `gpt-5.2`) |
| `API_VERSION` | OpenAI API version used by clients |
| `AI_GATEWAY_URL` | APIM URL for active demo (`.../ai`, then scripts derive per-demo paths) |
| `AI_GATEWAY_KEY` | APIM subscription key for gateway calls |
| `LOCAL_MODEL_URL`, `LOCAL_MODEL_NAME` | Ollama endpoint/model for bonus local-model demo |
| `REQUESTS_PER_TIER` | Requests per tier for Demo 2 load test |
| `SMARTAI_*` | Product-tier keys/descriptions for Premium/Economy/Developer |
| `NOISY_CUSTOMER_*` | Separate subscription keys/names for noisy-neighbor demos |
| `JWT_SECRET` | Shared HS256 secret for Demo 4 JWT generation/validation |
| `CREDIT_SERVICE_URL` | External credit-check service base URL |
| `MCP_SERVER_URL` | Optional MCP endpoint reference |
| `APPINSIGHTS_NAME`, `RESOURCE_GROUP`, `APIM_NAME` | Infra and monitoring helpers |

---

## 🎬 Demo 1 — Geographic Load Balancing (`/ai`)

**What it demonstrates:** APIM sends traffic to a geographic backend pool with managed identity auth. You can show normal use, burst pressure, and regional distribution.

- **APIM API path:** `/ai`
- **APIM policy:** `src/apim-policies/load-balancer-pool.xml`

Run:

```powershell
cd src
python .\demo1\good-app.py
python .\demo1\rogue-app.py
python .\demo1\load-test.py
```

Expected output: `x-ms-region`/`x-backend-region` headers and 429s under burst load.

---

## 🎬 Demo 2 — Smart Product-Based Routing (`/smartai`)

**What it demonstrates:** Product-tier routing and model override. Premium/Economy route to cloud balanced pool with different models; Developer routes to local Ollama.

- **APIM API path:** `/smartai`
- **APIM policy:** `src/apim-policies/smart-routing.xml`

Run:

```powershell
cd src
python .\demo2\smart-app.py
python .\demo2\smart-load-test.py
```

Expected output: `x-model-tier` and different `response.model` values (`gpt-5.2`, `gpt-4.1`, `phi4-mini`).

---

## 🎬 Demo 3a — Noisy Neighbor Rate Limit (`/noisyneighbor`)

**What it demonstrates:** Per-subscription fairness with calls/minute limits.

- **APIM API path:** `/noisyneighbor`
- **APIM policy:** `src/apim-policies/rate-limit.xml`

Run:

```powershell
cd src
python .\demo3\rate-limit-demo.py
```

Expected output: first calls succeed, then `429 THROTTLED` for over-limit customer.

---

## 🎬 Demo 3b — Monthly Token Quota (`/noisy-neighbor2`)

**What it demonstrates:** Per-subscription monthly token budget enforcement using LLM token-limit policy.

- **APIM API path:** `/noisy-neighbor2`
- **APIM policy:** `src/apim-policies/token-quota.xml`

Run:

```powershell
cd src
python .\demo3\quota-demo.py
```

Expected output: quota headers decrease, then `403 QUOTA EXCEEDED` when budget is exhausted.

---

## 🎬 Demo 4 — Enterprise JWT + Credit Service (`/inrivermock`)

**What it demonstrates:** Enterprise inbound controls: JWT validation, tenant extraction, and external credit check before forwarding to LLM.

- **APIM API path:** `/inrivermock`
- **APIM policy:** `src/apim-policies/enterprise-jwt-credits.xml`

Run:

```powershell
cd src
python .\demo4\generate-token.py --tenant tenant-adidas --user user1@adidas.com
python .\demo4\enterprise-app.py
```

Expected output: approved tenant gets model response + credit headers; low/no-credit tenant gets 403.

---

## ➕ Bonus — Local Model via APIM Passthrough (`/ollama`)

Run:

```powershell
cd src
python .\demo1\local-model.py
```

Expected output: direct local mode or governed APIM mode depending on `AI_GATEWAY_URL` + `AI_GATEWAY_KEY`.

---

📖 Detailed presenter guide: [`src/README.md`](./src/README.md)