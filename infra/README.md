# InRiver AI Gateway — Terraform

Terraform reescrito a partir del export Bicep en [`../rawinfra`](../rawinfra).

## Estructura

```
terraform/
├── providers.tf            # azurerm + azapi (versiones fijadas)
├── backend.tf              # local (cambia a azurerm cuando elijas storage)
├── variables.tf            # entrada global (project, env, location, tags…)
├── locals.tf               # naming convention centralizada
├── main.tf                 # RG + composición de módulos (ejemplo de uso)
├── outputs.tf
├── terraform.tfvars.example
├── secrets.auto.tfvars.example
└── modules/
    ├── observability/      # Log Analytics + Application Insights
    ├── acr/                # Container Registry + scope maps
    ├── container-apps/     # Managed Environment + Container App
    ├── ai-foundry/         # Cognitive (AIServices) + deployments + RAI + projects + Defender
    ├── apim/               # APIM service + global policy + named values + loggers + groups + users
    ├── apim-api/           # API + operations + policies + diagnostics (reutilizable)
    ├── apim-product/       # Product + APIs + groups + policies (reutilizable)
    └── apim-backend/       # Backend (reutilizable)
```

## Convención de nombres

`<proj>-<env>-<rtype>[-<workload>]`

| Token   | Valor               | Notas                                                       |
|---------|---------------------|-------------------------------------------------------------|
| `proj`  | `iagw`              | de `inriver-aigw`, encaja en el límite 24 chars del ACR     |
| `env`   | `dev` / `tst` / `prd` | 3 chars                                                   |
| `rtype` | CAF (`rg`, `apim`, `acr`, `law`, `appi`, `cae`, `ca`, `aih`) | |
| `workload` | opcional (p.ej. `mcp`) | para distinguir instancias                              |

Ejemplos para `env=prd`:

| Recurso              | Nombre              |
|----------------------|---------------------|
| Resource Group       | `iagw-prd-rg`       |
| APIM                 | `iagw-prd-apim`     |
| ACR (sin guiones)    | `iagwprdacr`        |
| ACA Environment      | `iagw-prd-cae`      |
| ACA App (MCP)        | `iagw-prd-ca-mcp`   |
| Log Analytics        | `iagw-prd-law`      |
| Application Insights | `iagw-prd-appi`     |
| AI Foundry (SEC)     | `iagw-prd-aih-sec`  |
| AI Foundry (ESP)     | `iagw-prd-aih-esp`  |
| AI Foundry (FRC)     | `iagw-prd-aih-frc`  |

Toda la convención vive en [`locals.tf`](locals.tf). Cambia ahí y se propaga.

## Uso

```bash
# 1. Copia y rellena tus valores
cp terraform.tfvars.example terraform.tfvars
cp secrets.auto.tfvars.example secrets.auto.tfvars   # NUNCA commitear

# 2. Login (la suscripción destino, distinta de la actual)
az login
az account set --subscription "<SUB_ID_NUEVA>"

# 3. Init + plan + apply
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

## Decisiones tomadas en la conversión

| Tema | Decisión |
|------|----------|
| **Alcance** | Solo infra "real" del Bicep. Las 1342 tablas de Log Analytics, 78 `savedSearches` y 13 `ProactiveDetectionConfigs` del export se **descartan** (son ruido auto-creado por Azure). |
| **State** | Recreación desde cero en una suscripción/RG nueva. Sin `terraform import`. |
| **Entornos** | Uno solo (`prd` por defecto, override vía tfvars). |
| **Backend** | Local. Para producción pasa a `azurerm` (esqueleto comentado en `backend.tf`). |
| **APIM content** | APIs, operations, policies XML y products → dentro de Terraform (versionado junto). |
| **OpenAI/AIServices deployments** | Dentro de Terraform (`azurerm_cognitive_deployment`). |
| **Imagen ACA** | `var.aca_image` con default a la imagen actual. CI/CD la sobreescribe libremente. |
| **Secretos** | Variables `sensitive=true` vía `secrets.auto.tfvars`. (Key Vault: TODO futuro). |
| **Providers** | `azurerm` para todo lo que cubre. `azapi` para recursos que `azurerm` aún no tiene bien soportados: AI Foundry `projects`, `defenderForAISettings`, `raiPolicies`, APIM `portalconfigs` y `templates`. |
| **Naming** | Nueva convención CAF (ver tabla arriba). |

## Pendiente / siguientes pasos

Este scaffold deja **interfaces y un módulo por dominio**. Para terminar la conversión 1:1 falta extraer del Bicep:

- [ ] 10 APIs APIM con sus 38 operations, 9 api/policies y 9 api/diagnostics → poblar `var.apim_apis`
- [ ] 9 products con sus APIs/groups/policies → poblar `var.apim_products`
- [ ] 6 backends → poblar `var.apim_backends`
- [ ] 3 named values (cualquiera con `@secure`) → `var.apim_named_values`
- [ ] 12 deployments OpenAI (modelo, versión, capacity, SKU) → poblar `deployments` en `var.ai_foundry_accounts`
- [ ] 6 RAI policies + 3 projects + 3 defender settings → idem
- [ ] Policy XML global y por API → ficheros bajo `modules/apim/policies/` y `modules/apim-api/policies/`

Cuando confirmes este scaffold, en el siguiente paso parseo `rawinfra` y relleno los `tfvars` con los valores reales.
