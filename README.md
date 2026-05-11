# 🤖 inRiver AI Gateway Demo Kit

> **Enterprise AI orchestration with multi-regional Azure AI Foundry, geographic load balancing, and intelligent product routing** — Built for the inRiver Partner Session

[![Azure Samples](https://img.shields.io/badge/Azure-Samples-0078D4?style=flat-square&logo=microsoft-azure)](https://github.com/Azure-Samples/AI-Gateway)
[![Python 3.11+](https://img.shields.io/badge/Python-3.11+-3776ab?style=flat-square&logo=python)](https://www.python.org/)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-5391FE?style=flat-square&logo=powershell)](https://learn.microsoft.com/en-us/powershell/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

---

## 📋 Table of Contents

- [🎯 What is This?](#-what-is-this)
- [🏗️ Architecture Overview](#-architecture-overview)
- [📊 Demo Structure](#-demo-structure)
- [📁 Project Layout](#-project-layout)
- [⚡ Quick Start](#-quick-start)
- [🔧 Configuration](#-configuration)
- [📚 Reference Links](#-reference-links)

---

## 🎯 What is This?

**inRiver AI Gateway** is a **demonstration kit** showcasing how enterprises can orchestrate AI workloads across Azure using:

- ✅ **Multi-regional deployment** — 3 Azure regions (Sweden, France, Spain) for resilience & compliance
- ✅ **Intelligent routing** — Azure API Management policies for geographic load balancing & failover
- ✅ **Azure AI Foundry** — Centralized AI model deployment & governance
- ✅ **Smart product routing** — LLM-powered intelligent request classification
- ✅ **MCP server integration** — FastMCP tool server deployed to Azure Container Apps
- ✅ **Production telemetry** — Application Insights monitoring & governance

Built as a **lab environment** for Microsoft partners exploring advanced AI deployment patterns.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Applications                      │
│  (demo1: good-app, rogue-app, load-test)                   │
│  (demo2: smart-app, smart-load-test)                       │
└───────────────────────┬─────────────────────────────────────┘
                        │ Azure Entra ID Auth
                        ▼
        ┌───────────────────────────────────┐
        │  Azure API Management (APIM)      │
        │  ├─ Load Balancer Policy          │
        │  ├─ Failover Circuit Breaker      │
        │  └─ Rate Limiting & Content Safety│
        └───────────────────────────────────┘
                        │
        ┌───────────────┼────────────────┬────────────────┐
        │               │                │                │
        ▼               ▼                ▼                ▼
    ┌─────────┐   ┌─────────┐      ┌─────────┐     ┌──────────┐
    │ 🇸🇪 Sweden  │ 🇫🇷 France  │      │ 🇪🇸 Spain   │     │ 📊 Logging   │
    │ Central │   │ Central │      │ Central  │     │ & Telemetry │
    │ (50%)   │   │ (30%)   │      │ (20%)    │     │ Application  │
    │         │   │         │      │          │     │ Insights     │
    │ Azure AI│   │ Azure AI│      │ Azure AI │     └──────────┘
    │ Foundry │   │ Foundry │      │ Foundry  │
    │ gpt-5.2 │   │ gpt-5.2 │      │ gpt-5.2  │
    └─────────┘   └─────────┘      └─────────┘
                        │
                        ▼
            ┌─────────────────────────┐
            │ Azure Container Apps    │
            │ (MCP Server - agentic)  │
            └─────────────────────────┘
                        │
                        ▼
            ┌─────────────────────────┐
            │ Local Model (Ollama)    │
            │ (Optional fallback)     │
            └─────────────────────────┘
```

### Regional Deployment

| 🌍 Region | 📍 Azure Region | 🎯 Weight | 📦 Deployment | 🔐 Auth |
|-----------|-----------------|-----------|---------------|---------|
| 🇸🇪 Sweden | `Sweden Central` | 50% | `gpt-5.2` | Entra ID |
| 🇫🇷 France | `France Central` | 30% | `gpt-5.2` | Entra ID |
| 🇪🇸 Spain | `Spain Central` | 20% | `gpt-5.2` | Entra ID |

---

## 📊 Demo Structure

### 🎯 **Demo 1: Geographic Load Balancing & Failover**

Demonstrates enterprise AI workload distribution across regions with intelligent failover.

**Included scenarios:**
- ✅ `good-app.py` — Well-behaved application with proper error handling
- ✅ `rogue-app.py` — Malformed requests to trigger circuit breaker
- ✅ `load-test.py` — Concurrent requests to observe load distribution

**What you'll see:**
- Geographic routing based on configured weights
- Automatic failover when regions become unavailable
- Rate limiting & policy enforcement via APIM
- Telemetry captured in Application Insights

### 🧠 **Demo 2: Smart Product Routing**

Demonstrates intelligent LLM-powered request classification and routing.

**Included scenarios:**
- ✅ `smart-app.py` — Production-ready routing engine
- ✅ `smart-load-test.py` — Load testing with semantic request classification

**What you'll see:**
- Requests classified by semantic intent
- Automatic routing to appropriate regional endpoints
- Confidence scoring & fallback handling
- Full request/response telemetry

---

## 📁 Project Layout

```
inRiverAIGateway/
├── README.md                           ← 🎯 You are here!
├── src/
│   ├── README.md                       ← 📖 Detailed demo guide
│   ├── .env                            ← 🔐 Environment config (create from template)
│   ├── requirements.txt                ← 📦 Python dependencies
│   │
│   ├── demo1/                          ← 🎯 Demo: Load Balancing & Failover
│   │   ├── good-app.py                 │  Standard client, proper error handling
│   │   ├── rogue-app.py                │  Malformed requests → circuit breaker
│   │   └── load-test.py                │  Concurrent load distribution test
│   │
│   ├── demo2/                          ← 🧠 Demo: Smart Routing
│   │   ├── smart-app.py                │  LLM-powered request classifier
│   │   └── smart-load-test.py          │  Semantic load testing
│   │
│   ├── mcp-server/                     ← 🤖 Model Context Protocol Server
│   │   ├── server.py                   │  FastMCP application server
│   │   ├── Dockerfile                  │  Container image definition
│   │   ├── requirements.txt            │  MCP dependencies
│   │   └── deploy-aca.ps1              │  Deploy to Azure Container Apps
│   │
│   ├── apim-policies/                  ← 📋 Azure APIM Policy Definitions
│   │   ├── load-balancer.xml           │  Geographic load balancing policy
│   │   └── failover-circuit-breaker.xml│ Failover with circuit breaker
│   │
│   ├── arm-templates/                  ← 🏗️ Infrastructure as Code
│   │   ├── foundry-*.json              │  Azure AI Foundry deployment
│   │   └── apim-*.json                 │  API Management configuration
│   │
│   ├── provision-resources.ps1         ← 🚀 Deploy all regional Foundry stacks
│   └── inject-policies.ps1             ← 💉 Apply APIM policies
│
└── .env.example                        ← 📝 Environment template

```

---

## ⚡ Quick Start

### 🔑 Prerequisites

Before you begin, ensure you have:

- ✅ **Python 3.11+** ([download](https://www.python.org/downloads/))
- ✅ **Azure subscription** with permissions to create resources
- ✅ **Azure CLI** (`az` command)
- ✅ **PowerShell 7.0+** ([download](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell))
- ✅ **Git** for version control
- ⭐ **Ollama** (optional) for local model fallback — [download](https://ollama.ai)

### 📦 Installation (5 minutes)

```powershell
# 1️⃣ Clone the repository
git clone https://github.com/Azure-Samples/inRiverAIGateway.git
cd inRiverAIGateway

# 2️⃣ Create & configure environment
cd src
Copy-Item .env.example .env
# ✏️ Edit .env with your Azure resource names and endpoints
code .env

# 3️⃣ Install Python dependencies
pip install -r .\requirements.txt

# 4️⃣ Authenticate to Azure
az login
```

### 🚀 Running the Demos

<details open>
<summary><b>✨ Demo 1: Load Balancing & Failover</b></summary>

```powershell
cd src

# 📊 Standard application
python .\demo1\good-app.py

# 🔴 Trigger circuit breaker (rogue requests)
python .\demo1\rogue-app.py

# 📈 Load test with distribution metrics
python .\demo1\load-test.py
```

**Expected output:**
- Requests distributed: Sweden 50%, France 30%, Spain 20%
- Circuit breaker triggered after 5 consecutive failures
- Automatic failover to next region
- Full telemetry in Application Insights

</details>

<details>
<summary><b>🧠 Demo 2: Smart Routing</b></summary>

```powershell
cd src

# 🎯 Intelligent routing engine
python .\demo2\smart-app.py

# 📈 Load test with semantic classification
python .\demo2\smart-load-test.py
```

**Expected output:**
- Requests classified by intent (product search, info retrieval, etc.)
- Confidence scoring for each classification
- Optimized routing based on semantic categories
- Detailed telemetry with classification metrics

</details>

---

## 🔧 Configuration

### 📝 Environment Variables (`.env`)

| Variable | Example | Purpose |
|----------|---------|---------|
| `APIM_NAME` | `inriver-aigw-apim` | Azure API Management instance |
| `APIM_URL` | `https://inriver-aigw-apim.azure-api.net` | APIM endpoint URL |
| `FOUNDRY_SWEDEN_ENDPOINT` | `https://inriver-aigw-foundry-sec.openai.azure.com/` | Sweden Foundry endpoint |
| `FOUNDRY_FRANCE_ENDPOINT` | `https://inriver-aigw-foundry-frc.openai.azure.com/` | France Foundry endpoint |
| `FOUNDRY_SPAIN_ENDPOINT` | `https://inriver-aigw-foundry-esp.openai.azure.com/` | Spain Foundry endpoint |
| `AZURE_DEPLOYMENT_NAME` | `gpt-5.2` | Model deployment identifier |
| `AZURE_TENANT_ID` | `{your-tenant-id}` | Azure Entra ID tenant |
| `OLLAMA_URL` | `http://localhost:11434` | Local Ollama (optional) |

### 💉 Injecting APIM Policies

```powershell
cd src

# Apply load balancing policy (Sweden 50%, France 30%, Spain 20%)
.\inject-policies.ps1 -ApimName "inriver-aigw-apim" `
                       -ApiId "ai-gateway-api" `
                       -PolicyName "load-balancer"

# Apply circuit breaker & failover policy
.\inject-policies.ps1 -ApimName "inriver-aigw-apim" `
                       -ApiId "ai-gateway-api" `
                       -PolicyName "failover-circuit-breaker"
```

### 🚀 Provisioning Regional Resources

```powershell
cd src

# Deploy all 3 regional Azure AI Foundry stacks with ARM templates
.\provision-resources.ps1 -Environment "production" `
                          -Regions @("Sweden Central", "France Central", "Spain Central")
```

---

## 📚 Reference Links

### 🔗 Official Documentation

- **[Azure-Samples/AI-Gateway](https://github.com/Azure-Samples/AI-Gateway)** — Comprehensive AI Gateway lab & best practices
- **[Azure API Management](https://learn.microsoft.com/en-us/azure/api-management/)** — Enterprise API governance & policies
- **[Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/)** — Model deployment & management
- **[Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/)** — Serverless container hosting
- **[Model Context Protocol (MCP)](https://modelcontextprotocol.io/)** — Tool integration standard for LLMs

### 📖 For More Details

👉 **See [`src/README.md`](./src/README.md)** for detailed demo instructions, troubleshooting, and advanced configuration.

---

## 🤝 Contributing

This is a **lab kit for educational purposes**. Contributions, issues, and feature requests are welcome!

## 📄 License

Licensed under the MIT License — see the LICENSE file for details.

---

**Built for inRiver Partner Session | Microsoft Azure Demo Kit** 🎯
