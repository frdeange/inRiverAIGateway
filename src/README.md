# 🎯 AI Gateway Demo - Detailed Instructions

> **Real Azure Foundry deployment** for the inRiver Partner Session  
> Last synced: **2026-05-11T15:21:43.368+02:00**

[![Status](https://img.shields.io/badge/Status-Production-green?style=flat-square)](.)
[![Environment](https://img.shields.io/badge/Environment-Azure%20AI%20Foundry-0078D4?style=flat-square&logo=microsoft-azure)](.)

---

## 📋 Quick Navigation

- [🔐 Resources](#-azure-resources)
- [⚙️ Setup](#-setup--configuration)
- [🎯 Demo 1: Load Balancing](#-demo-1-geographic-load-balancing--failover)
- [🧠 Demo 2: Smart Routing](#-demo-2-smart-product-routing)
- [🚀 Deployment](#-deployment)
- [📊 Monitoring](#-monitoring--telemetry)
- [🐛 Troubleshooting](#-troubleshooting)

---

## 🔐 Azure Resources

Your live environment is provisioned in the **West Europe** region across **3 regional Foundry stacks**:

### 📍 Resource Group

| Resource | Name | Type |
|----------|------|------|
| 📂 Resource Group | `rg-inRiverAIGW` | Container |
| 📊 Log Analytics | `inriver-aigw-log` | Monitoring |
| 👁️ App Insights | `inriver-aigw-apim` | Telemetry |

### 🤖 Azure AI Foundry Deployments

| 🌍 Region | 📦 Foundry Resource | 🎯 Project | ⚡ Model |
|-----------|-------------------|-----------|--------|
| 🇸🇪 Sweden Central | `inriver-aigw-foundry-sec` | `inriver-aigw-foundry-sec-PROJECT` | `gpt-5.2` |
| 🇫🇷 France Central | `inriver-aigw-foundry-frc` | `inriver-aigw-foundry-frc-PROJECT` | `gpt-5.2` |
| 🇪🇸 Spain Central | `inriver-aigw-foundry-esp` | `inriver-aigw-foundry-esp-PROJECT` | `gpt-5.2` |

### 🌐 API Management & Containers

| Resource | Name | Purpose |
|----------|------|---------|
| 🏛️ APIM Instance | `inriver-aigw-apim` | Route/govern traffic |
| 🐳 ACA Environment | `inriver-aigw-acaenv` | Container runtime |
| 🤖 MCP Server | `inriver-aigw-acamcp` | Tool server |

---

## ⚙️ Setup & Configuration

### 1️⃣ Environment Configuration

Create your `.env` file from the template:

```powershell
cd C:\repos\inRiverAIGateway\src
Copy-Item .env.example .env
code .env
```

### ✏️ Required Environment Variables

```bash
# 🏛️ Azure API Management
APIM_NAME="inriver-aigw-apim"
APIM_URL="https://inriver-aigw-apim.azure-api.net"

# 🇸🇪 Sweden Central
FOUNDRY_SWEDEN_ENDPOINT="https://inriver-aigw-foundry-sec.openai.azure.com/"

# 🇫🇷 France Central
FOUNDRY_FRANCE_ENDPOINT="https://inriver-aigw-foundry-frc.openai.azure.com/"

# 🇪🇸 Spain Central
FOUNDRY_SPAIN_ENDPOINT="https://inriver-aigw-foundry-esp.openai.azure.com/"

# 🤖 Model Deployment
AZURE_DEPLOYMENT_NAME="gpt-5.2"

# 🔐 Entra ID
AZURE_TENANT_ID="your-tenant-id-here"

# ⭐ Local Model (Optional)
OLLAMA_URL="http://localhost:11434"
```

### 2️⃣ Install Dependencies

```powershell
# Ensure you're in src/
cd C:\repos\inRiverAIGateway\src

# Install Python packages
pip install -r .\requirements.txt

# Verify installation
python -c "import openai; import azure.identity; print('✅ Dependencies installed!')"
```

### 📦 Included Libraries

| Package | Version | Purpose |
|---------|---------|---------|
| `openai` | ≥1.0 | Azure OpenAI client |
| `azure-identity` | ≥1.15 | Entra ID authentication (`DefaultAzureCredential`) |
| `python-dotenv` | ≥1.0 | Load `.env` configuration |

**Authentication:**  
All clients use `DefaultAzureCredential` — no API keys required (assumes `disableLocalAuth=true`).

### 3️⃣ Authenticate to Azure

```powershell
# Login with your Azure account
az login

# Set default subscription (if needed)
az account set --subscription "Your Subscription Name"

# Verify you're authenticated
az account show
```

---

## 🎯 Demo 1: Geographic Load Balancing & Failover

Learn how APIM intelligently distributes AI requests across 3 Azure regions.

### 🎬 Scenario

**Request Distribution:**
- 🇸🇪 Sweden Central: **50%** (primary)
- 🇫🇷 France Central: **30%** (secondary)
- 🇪🇸 Spain Central: **20%** (tertiary)

**Failover Chain:**  
Sweden → France → Spain → Circuit Breaker

### 📋 Prerequisites

✅ All environment variables configured in `.env`  
✅ Python 3.11+ with dependencies installed  
✅ Authenticated to Azure CLI

### 💉 Step 1: Inject APIM Policies

```powershell
cd C:\repos\inRiverAIGateway\src

# Apply load balancing policy
.\inject-policies.ps1 -ApimName "inriver-aigw-apim" `
                      -ApiId "ai-gateway-api" `
                      -PolicyName "load-balancer"

# Apply circuit breaker & failover policy
.\inject-policies.ps1 -ApimName "inriver-aigw-apim" `
                      -ApiId "ai-gateway-api" `
                      -PolicyName "failover-circuit-breaker"
```

**Policy details:**
- `load-balancer.xml` — Distributes traffic by region weight
- `failover-circuit-breaker.xml` — Automatic failover on repeated failures

### 🎬 Step 2: Run Demo Scripts

#### ✅ Good App (Standard Behavior)

```powershell
python .\demo1\good-app.py
```

**Output example:**
```
✅ Connected to inriver-aigw-apim
📍 Request 1 → Sweden Central (50% weight)
Response: "The sky is blue because..."
⏱️ Latency: 245ms

📍 Request 2 → France Central (30% weight)
Response: "Product availability in EU..."
⏱️ Latency: 267ms

📍 Request 3 → Sweden Central (50% weight)
Response: "Inventory management best practices..."
⏱️ Latency: 231ms
```

#### 🔴 Rogue App (Circuit Breaker)

```powershell
python .\demo1\rogue-app.py
```

**What happens:**
1. Sends malformed requests to trigger errors
2. After 5 consecutive failures → **circuit breaker opens**
3. Subsequent requests immediately fail (fast-fail)
4. Observe telemetry in Application Insights

**Output example:**
```
⚠️ Sending malformed requests...
❌ Request 1: 400 Bad Request
❌ Request 2: 400 Bad Request
❌ Request 3: 400 Bad Request
❌ Request 4: 400 Bad Request
❌ Request 5: 400 Bad Request
🛑 CIRCUIT BREAKER TRIGGERED

⏹️ Subsequent requests fail immediately (open circuit)
```

#### 📈 Load Test (Distribution Metrics)

```powershell
python .\demo1\load-test.py
```

**Output example:**
```
🚀 Running load test: 30 concurrent requests...

📊 Distribution Results:
  🇸🇪 Sweden Central:  15 requests (50%) ✅
  🇫🇷 France Central:  9 requests  (30%) ✅
  🇪🇸 Spain Central:   6 requests  (20%) ✅

📈 Latency Statistics:
  Min: 210ms
  Max: 490ms
  Avg: 315ms
  P95: 420ms

✅ Load test completed
```

---

## 🧠 Demo 2: Smart Product Routing

Experience LLM-powered intelligent request classification and semantic routing.

### 🎯 Scenario

The smart router:
1. Analyzes incoming product queries
2. Classifies by semantic intent (product search, inventory check, recommendations)
3. Routes to optimal regional endpoint
4. Provides confidence scoring
5. Logs full request/response lifecycle

### 📋 Prerequisites

✅ Demo 1 setup complete  
✅ APIM policies injected  
✅ All regional endpoints operational

### 🎬 Running Smart Routing

#### 🧠 Smart App

```powershell
python .\demo2\smart-app.py
```

**Output example:**
```
🧠 Initializing semantic router...
✅ Connected to gpt-5.2 deployment

🔍 Analyzing request: "What wireless earbuds are trending?"

📊 Classification Results:
  Intent: product_search
  Confidence: 0.94
  Category: Electronics → Wearables
  
  Optimal Region: 🇸🇪 Sweden Central (semantic match)
  Primary Weight: 50%

🌐 Routing to Sweden Central...
⏱️ Latency: 254ms

📋 Response:
"The most trending wireless earbuds currently include:
1. Sony WH-1000XM5 (Noise Cancellation)
2. Apple AirPods Pro 2 (Seamless Integration)
3. Bose QuietComfort Ultra (Comfort Design)"

✅ Request logged to Application Insights
```

#### 📈 Smart Load Test

```powershell
python .\demo2\smart-load-test.py
```

**Output example:**
```
🚀 Running semantic load test: 20 requests...

📊 Classification Breakdown:
  product_search:      8 requests (40%) → Sweden
  inventory_check:     7 requests (35%) → France
  recommendations:     5 requests (25%) → Spain

📈 Confidence Distribution:
  High (>0.9):   18 requests (90%)
  Medium (0.7-0.9): 2 requests (10%)
  Low (<0.7):    0 requests

⏱️ Average Latency by Category:
  product_search:    285ms
  inventory_check:   312ms
  recommendations:   267ms

✅ Load test completed
```

---

## 🚀 Deployment

### 📦 Deploy MCP Server to Azure Container Apps

The FastMCP server provides agentic tool integration.

```powershell
cd C:\repos\inRiverAIGateway\src\mcp-server

# Deploy to Azure Container Apps
.\deploy-aca.ps1
```

**Under the hood:**
```powershell
az containerapp up `
  --name inriver-aigw-acamcp `
  --environment inriver-aigw-acaenv `
  --resource-group rg-inRiverAIGW `
  --source . `
  --ingress external `
  --target-port 8000
```

**Verify deployment:**
```powershell
# Get the ACA app URL
az containerapp show --name inriver-aigw-acamcp `
                     --resource-group rg-inRiverAIGW `
                     --query properties.configuration.ingress.fqdn

# Test the endpoint
curl https://inriver-aigw-acamcp.<region>.azurecontainerapps.io/health
```

### 🏗️ Provision Regional Foundry Resources

Deploy all 3 regional Azure AI Foundry stacks:

```powershell
cd C:\repos\inRiverAIGateway\src

# Full provisioning (requires permissions)
.\provision-resources.ps1 -Environment "production" `
                          -Regions @("Sweden Central", "France Central", "Spain Central")
```

---

## 📊 Monitoring & Telemetry

### 👁️ Application Insights Dashboard

All telemetry flows to `inriver-aigw-apim` (Application Insights).

```powershell
# Open Application Insights
az portal open --resource-group rg-inRiverAIGW --name inriver-aigw-apim
```

### 📈 Key Metrics to Monitor

| Metric | Location | Insights |
|--------|----------|----------|
| **Request Rate** | Performance → Custom Events | Requests/sec per region |
| **Response Time** | Performance → Response Time | Latency by endpoint |
| **Error Rate** | Failures → Failed Requests | Circuit breaker triggers |
| **Classification Confidence** | Custom Events → Smart Routing | LLM confidence scores |
| **Failover Events** | Alerts → APIM Events | Automatic region switches |

### 🔍 Custom KQL Queries

```kusto
// Distribution by region (last hour)
customEvents
| where name == "request_routed"
| summarize count() by tostring(customDimensions.region)
| render piechart

// Average latency by demo
customEvents
| where name in ("demo1_executed", "demo2_executed")
| summarize avg(customMeasurements.latency_ms) by name
| render columnchart

// Classification confidence distribution
customEvents
| where name == "classification_complete"
| summarize
    high=count(customMeasurements.confidence > 0.9),
    medium=count(customMeasurements.confidence between (0.7, 0.9)),
    low=count(customMeasurements.confidence < 0.7)
```

---

## 🐛 Troubleshooting

### ❌ Issue: "Unauthorized (401)" on APIM calls

**Solution:**
```powershell
# Verify Entra ID authentication
az account show

# Refresh Azure CLI token
az account clear
az login
```

### ❌ Issue: "Circuit breaker open" - all requests failing

**Solution:**
```powershell
# Check APIM policy status
az apim api policy show --resource-group rg-inRiverAIGW `
                        --apim-name inriver-aigw-apim `
                        --api-id ai-gateway-api `
                        --policy-id failover-circuit-breaker

# Reset circuit breaker (update policy timestamp)
.\inject-policies.ps1 -ApimName "inriver-aigw-apim" `
                      -ApiId "ai-gateway-api" `
                      -PolicyName "failover-circuit-breaker" `
                      -Reset
```

### ❌ Issue: ".env file not found"

**Solution:**
```powershell
# Ensure you're in the src/ directory
cd C:\repos\inRiverAIGateway\src
ls .env

# If missing, create from template
Copy-Item .env.example .env
```

### ❌ Issue: "Module not found: openai"

**Solution:**
```powershell
# Reinstall dependencies
pip install --upgrade -r .\requirements.txt

# Verify installation
python -c "import openai; print(openai.__version__)"
```

### ❌ Issue: "Connection timeout to Foundry endpoint"

**Possible causes:**
- ❌ Endpoint URL misconfigured in `.env`
- ❌ Regional Foundry resource not deployed
- ❌ Network/firewall blocking outbound traffic

**Solution:**
```powershell
# Test connectivity
curl https://inriver-aigw-foundry-sec.openai.azure.com/status

# Verify resource exists
az cognitiveservices account show --resource-group rg-inRiverAIGW `
                                  --name inriver-aigw-foundry-sec
```

---

## 🔗 Reference & Documentation

- 📚 **[Root README](../README.md)** — Project overview & architecture
- 🏛️ **[Azure API Management](https://learn.microsoft.com/en-us/azure/api-management/)** — Policy definitions & governance
- 🤖 **[Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/)** — Model deployment
- 🐳 **[Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/)** — MCP server hosting
- 💻 **[Model Context Protocol](https://modelcontextprotocol.io/)** — Tool integration spec
- 🧪 **[Azure-Samples/AI-Gateway](https://github.com/Azure-Samples/AI-Gateway)** — Official lab guide

---

**Last updated:** 2026-05-11 | **Environment:** Production | **Status:** ✅ Active
