###############################################################################
# Cognitive Services account (kind = AIServices) — the AI Foundry "hub"
###############################################################################
resource "azurerm_cognitive_account" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "AIServices"
  sku_name            = var.sku_name

  custom_subdomain_name         = var.name
  public_network_access_enabled = true
  local_auth_enabled            = var.local_auth_enabled

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Enable Foundry project management on the AIServices account.
# azurerm 4.x does not yet expose `allowProjectManagement`, so we patch
# the account via azapi after creation.
resource "azapi_update_resource" "allow_project_management" {
  count = var.allow_project_management ? 1 : 0

  type        = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"
  resource_id = azurerm_cognitive_account.this.id

  body = {
    properties = {
      allowProjectManagement = true
    }
  }
}

###############################################################################
# Custom RAI (content filter) policies — azapi (azurerm has no first-class type)
###############################################################################
resource "azapi_resource" "rai_policy" {
  for_each = var.rai_policies

  type      = "Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01"
  parent_id = azurerm_cognitive_account.this.id
  name      = each.key

  body = {
    properties = {
      mode           = each.value.mode
      basePolicyName = each.value.base_policy_name
      contentFilters = each.value.content_filters_raw
    }
  }

  response_export_values = ["name", "id"]
}

###############################################################################
# Model deployments (gpt-4o, embeddings, etc.)
###############################################################################
resource "azurerm_cognitive_deployment" "this" {
  for_each = var.deployments

  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.this.id
  rai_policy_name      = each.value.rai_policy_name

  model {
    format  = each.value.model_format
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = each.value.sku_name
    capacity = each.value.sku_capacity
  }

  depends_on = [azapi_resource.rai_policy]
}

###############################################################################
# Defender for AI per-account settings — azapi
###############################################################################
resource "azapi_resource" "defender_for_ai" {
  count = var.defender_for_ai_enabled ? 1 : 0

  type      = "Microsoft.CognitiveServices/accounts/defenderForAISettings@2024-10-01"
  parent_id = azurerm_cognitive_account.this.id
  name      = "Default"

  body = {
    properties = {
      state = "Enabled"
    }
  }
}

###############################################################################
# AI Foundry projects — azapi (azurerm has no resource yet)
###############################################################################
resource "azapi_resource" "project" {
  for_each = var.projects

  type      = "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview"
  parent_id = azurerm_cognitive_account.this.id
  name      = each.key
  location  = var.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      displayName = coalesce(each.value.display_name, each.key)
      description = each.value.description
    }
  }

  response_export_values = ["id", "identity.principalId"]
  tags                   = var.tags
}
