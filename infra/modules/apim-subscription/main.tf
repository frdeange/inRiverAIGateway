resource "azurerm_api_management_subscription" "this" {
  subscription_id     = var.subscription_id
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  display_name        = var.display_name
  state               = var.state
  allow_tracing       = var.allow_tracing

  api_id     = var.api_id
  product_id = var.product_id
}
