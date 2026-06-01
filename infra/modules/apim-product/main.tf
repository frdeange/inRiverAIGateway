resource "azurerm_api_management_product" "this" {
  product_id            = var.product_id
  api_management_name   = var.api_management_name
  resource_group_name   = var.resource_group_name
  display_name          = var.display_name
  description           = var.description
  subscription_required = var.subscription_required
  approval_required     = var.subscription_required ? var.approval_required : false
  published             = var.published
  subscriptions_limit   = var.subscriptions_limit
}

resource "azurerm_api_management_product_api" "this" {
  for_each = toset(var.api_names)

  product_id          = azurerm_api_management_product.this.product_id
  api_name            = each.value
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_api_management_product_group" "this" {
  for_each = toset(var.group_names)

  product_id          = azurerm_api_management_product.this.product_id
  group_name          = each.value
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_api_management_product_policy" "this" {
  count = var.policy_file == "" ? 0 : 1

  product_id          = azurerm_api_management_product.this.product_id
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  xml_content         = file(var.policy_file)
}
