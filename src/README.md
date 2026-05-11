# AI Gateway Demo (Real Azure Resources)

This src folder is aligned with the live environment as of **2026-05-11T02:27:49.189+02:00**.

## Real resources

- Resource Group: `rg-inRiverAIGW`
- Log Analytics: `inriver-aigw-log`
- Application Insights: `inriver-aigw-apim`
- Foundry Sweden Central: `inriver-aigw-foundry-sec` (project: `inriver-aigw-foundry-sec-PROJECT`)
- Foundry France Central: `inriver-aigw-foundry-frc` (project: `inriver-aigw-foundry-frc-PROJECT`)
- Foundry Spain Central: `inriver-aigw-foundry-esp` (project: `inriver-aigw-foundry-esp-PROJECT`)
- Deployment name: `gpt-5.2`
- ACA environment: `inriver-aigw-acaenv`
- ACA app: `inriver-aigw-acamcp`

## 1) Configure demo environment

`src/.env` now contains all real names and endpoints.

## 2) Install SDK dependencies

From `src`:

```powershell
pip install -r .\requirements.txt
```

The clients now use:
- `openai` (`AzureOpenAI` client)
- `azure-identity` (`DefaultAzureCredential` for Entra ID auth)
- `python-dotenv` (loads `src\.env`)

With `disableLocalAuth=true`, API keys are not required.

## 3) APIM policy injection

Apply one policy at a time with your APIM name and API ID:

```powershell
cd C:\repos\inRiverAIGateway\src
.\inject-policies.ps1 -ApimName <apim-name> -ApiId <api-id> -PolicyName load-balancer
.\inject-policies.ps1 -ApimName <apim-name> -ApiId <api-id> -PolicyName failover-circuit-breaker
```

Policy updates included:
- Load balancer weights: Sweden 50%, France 30%, Spain 20%
- Failover chain: Sweden -> France -> Spain
- Deployment route: `gpt-5.2`

## 4) Run demo clients

From `src`:

```powershell
python .\demo1\good-app.py
python .\demo1\rogue-app.py
python .\demo1\load-test.py
python .\demo2\smart-app.py
```

Clients read values from `src/.env` (or environment variables) and authenticate via Entra ID with `DefaultAzureCredential`.

## 5) Deploy the FastMCP server to Azure Container Apps

From `src\mcp-server`:

```powershell
.\deploy-aca.ps1
```

This uses:

```powershell
az containerapp up `
  --name inriver-aigw-acamcp `
  --environment inriver-aigw-acaenv `
  --resource-group rg-inRiverAIGW `
  --source . `
  --ingress external `
  --target-port 8000
```

## 6) Updated demo flow with real endpoints

1. Inject APIM policies for governance/load-balancing/failover.
2. Run good/rogue/load scripts against Foundry `gpt-5.2` endpoints (`*.openai.azure.com`) with Entra ID auth.
3. Observe telemetry in `inriver-aigw-apim` (Application Insights).
4. Deploy and validate MCP tool endpoint at ACA URL (`inriver-aigw-acamcp.<region>.azurecontainerapps.io`).

## Reference

For official lab notebooks and comprehensive AI Gateway scenarios, see the [Azure-Samples/AI-Gateway](https://github.com/Azure-Samples/AI-Gateway) repository. It contains detailed guides for all AI Gateway use cases and best practices.
