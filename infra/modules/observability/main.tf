resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name_law
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.law_sku
  retention_in_days   = var.law_retention_days
  daily_quota_gb      = -1

  internet_ingestion_enabled = true
  internet_query_enabled     = true

  tags = var.tags
}

resource "azurerm_application_insights" "this" {
  name                = var.name_appi
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.this.id
  retention_in_days   = var.app_insights_retention_days

  internet_ingestion_enabled = true
  internet_query_enabled     = true

  tags = var.tags
}
