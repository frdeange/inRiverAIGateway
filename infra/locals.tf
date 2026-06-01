###############################################################################
# Centralized naming convention. Change here, propagates everywhere.
#
# Pattern: <project>-<environment>-<rtype>[-<workload>]
# ACR/Storage exceptions (alphanumeric-only) strip the hyphens.
###############################################################################
locals {
  name_prefix = "${var.project}-${var.environment}" # iagw-prd

  names = {
    resource_group       = coalesce(var.resource_group_name_override, "${local.name_prefix}-rg")
    log_analytics        = "${local.name_prefix}-law"
    application_insights = "${local.name_prefix}-appi"
    acr                  = lower(replace("${local.name_prefix}acr", "-", "")) # iagwprdacr
    aca_environment      = "${local.name_prefix}-cae"
    aca_app              = "${local.name_prefix}-ca-${var.aca_workload}"
    apim                 = "${local.name_prefix}-apim"
  }

  # AI Foundry per-region names: iagw-prd-aih-<region_code>
  ai_foundry_names = {
    for k, _ in var.ai_foundry_accounts :
    k => "${local.name_prefix}-aih-${k}"
  }

  default_tags = {
    project     = var.project
    environment = var.environment
    workload    = "ai-gateway"
    managed-by  = "terraform"
    source      = "github.com/inriver/InRiverAIGW-Infra"
  }

  tags = merge(local.default_tags, var.extra_tags)

  # APIM SKU is exposed as "<sku>_<capacity>" (e.g. BasicV2_1).
  apim_sku_parts    = split("_", var.apim_sku_name)
  apim_sku_tier     = local.apim_sku_parts[0]
  apim_sku_capacity = tonumber(local.apim_sku_parts[1])
}