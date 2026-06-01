resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  public_network_access_enabled = true
  anonymous_pull_enabled        = false
  data_endpoint_enabled         = false

  retention_policy_in_days = 7

  tags = var.tags
}

resource "azurerm_container_registry_scope_map" "this" {
  for_each = var.scope_maps

  name                    = each.key
  container_registry_name = azurerm_container_registry.this.name
  resource_group_name     = var.resource_group_name
  description             = each.value.description
  actions                 = each.value.actions
}
