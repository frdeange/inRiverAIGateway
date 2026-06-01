###############################################################################
# Resource group
###############################################################################
resource "azurerm_resource_group" "this" {
  name     = local.names.resource_group
  location = var.primary_location
  tags     = local.tags
}

###############################################################################
# Observability
###############################################################################
module "observability" {
  source = "./modules/observability"

  name_law            = local.names.log_analytics
  name_appi           = local.names.application_insights
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  law_retention_days          = var.law_retention_days
  app_insights_retention_days = var.app_insights_retention_days

  tags = local.tags
}

###############################################################################
# Container Registry
###############################################################################
module "acr" {
  source = "./modules/acr"

  name                = local.names.acr
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled

  tags = local.tags
}

###############################################################################
# Container Apps
###############################################################################
module "container_apps" {
  source = "./modules/container-apps"

  name_env            = local.names.aca_environment
  name_app            = local.names.aca_app
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  log_analytics_workspace_id = module.observability.log_analytics_workspace_id
  acr_id                     = module.acr.id
  acr_login_server           = module.acr.login_server

  image        = var.aca_image
  target_port  = var.aca_target_port
  cpu          = var.aca_cpu
  memory       = var.aca_memory
  min_replicas = var.aca_scale_min
  max_replicas = var.aca_scale_max

  tags = local.tags
}

###############################################################################
# AI Foundry (AIServices) — instantiated once per region
###############################################################################
module "ai_foundry" {
  source   = "./modules/ai-foundry"
  for_each = var.ai_foundry_accounts

  name                = local.ai_foundry_names[each.key]
  resource_group_name = azurerm_resource_group.this.name
  location            = each.value.location
  sku_name            = each.value.sku_name

  local_auth_enabled       = each.value.local_auth_enabled
  allow_project_management = each.value.allow_project_management
  defender_for_ai_enabled  = each.value.defender_for_ai_enabled

  deployments  = each.value.deployments
  rai_policies = each.value.rai_policies
  projects     = each.value.projects

  tags = local.tags
}

###############################################################################
# APIM
###############################################################################
module "apim" {
  source = "./modules/apim"

  name                = local.names.apim
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku_name            = local.apim_sku_tier
  sku_capacity        = local.apim_sku_capacity

  publisher_email = var.apim_publisher_email
  publisher_name  = var.apim_publisher_name

  app_insights_id                  = module.observability.application_insights_id
  app_insights_instrumentation_key = module.observability.application_insights_instrumentation_key
  law_id                           = module.observability.log_analytics_workspace_id

  global_policy_file = "${path.module}/policies/global.xml"

  named_values        = var.apim_named_values
  named_value_secrets = var.apim_named_value_secrets

  groups        = var.apim_groups
  users         = var.apim_users
  notifications = var.apim_notifications

  tags = local.tags
}

###############################################################################
# APIM backends — one azurerm_api_management_backend per entry in var.apim_backends
###############################################################################
module "apim_backends" {
  source   = "./modules/apim-backend"
  for_each = var.apim_backends

  name                = each.key
  api_management_name = module.apim.name
  resource_group_name = module.apim.resource_group_name

  protocol                       = each.value.protocol
  url                            = each.value.url
  description                    = each.value.description
  resource_id                    = each.value.resource_id
  tls_validate_certificate_chain = each.value.tls_validate
  tls_validate_certificate_name  = each.value.tls_validate

  circuit_breaker_rules = each.value.circuit_breaker_rules
}

###############################################################################
# APIM backend pools (azapi — round-robin / priority over single backends)
###############################################################################
module "apim_backend_pools" {
  source   = "./modules/apim-backend-pool"
  for_each = var.apim_backend_pools

  name        = each.key
  apim_id     = module.apim.id
  description = each.value.description

  services = [
    for s in each.value.services : {
      backend_id = module.apim_backends[s.backend_name].id
      weight     = s.weight
      priority   = s.priority
    }
  ]

  depends_on = [module.apim_backends]
}

###############################################################################
# APIM APIs (reusable submodule, one instance per entry)
###############################################################################
module "apim_apis" {
  source   = "./modules/apim-api"
  for_each = var.apim_apis

  api_management_name = module.apim.name
  resource_group_name = module.apim.resource_group_name
  appi_logger_id      = module.apim.appi_logger_id

  name                  = each.key
  display_name          = each.value.display_name
  path                  = each.value.path
  protocols             = try(each.value.protocols, ["https"])
  service_url           = try(each.value.service_url, null)
  subscription_required = try(each.value.subscription_required, true)
  revision              = try(each.value.revision, "1")

  subscription_key_header_name      = try(each.value.subscription_key_header_name, "Ocp-Apim-Subscription-Key")
  subscription_key_query_param_name = try(each.value.subscription_key_query_param_name, "subscription-key")

  import_format  = try(each.value.import_format, null)
  import_content = try(each.value.import_content, null)

  operations  = try(each.value.operations, {})
  policy_file = try(each.value.policy_file, "")
}

###############################################################################
# APIM products
###############################################################################
module "apim_products" {
  source   = "./modules/apim-product"
  for_each = var.apim_products

  api_management_name = module.apim.name
  resource_group_name = module.apim.resource_group_name

  product_id   = each.key
  display_name = each.value.display_name
  description  = try(each.value.description, null)

  subscription_required = try(each.value.subscription_required, true)
  approval_required     = try(each.value.approval_required, false)
  published             = try(each.value.published, true)
  subscriptions_limit   = try(each.value.subscriptions_limit, null)

  api_names   = try(each.value.api_names, [])
  group_names = try(each.value.group_names, [])
  policy_file = try(each.value.policy_file, "")

  depends_on = [
    module.apim_apis,
    module.apim,
  ]
}

###############################################################################
# APIM subscriptions (kept separate to break the apim ↔ apim_products cycle)
###############################################################################
module "apim_subscriptions" {
  source   = "./modules/apim-subscription"
  for_each = var.apim_subscriptions

  subscription_id     = each.key
  api_management_name = module.apim.name
  resource_group_name = module.apim.resource_group_name
  display_name        = each.value.display_name
  state               = each.value.state
  allow_tracing       = each.value.allow_tracing

  api_id = (
    each.value.scope_kind == "api" && each.value.scope_target != null
    ? module.apim_apis[each.value.scope_target].id
    : null
  )
  product_id = (
    each.value.scope_kind == "product" && each.value.scope_target != null
    ? module.apim_products[each.value.scope_target].id
    : null
  )

  depends_on = [
    module.apim_apis,
    module.apim_products,
  ]
}
