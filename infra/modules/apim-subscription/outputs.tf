output "id" {
  value = azurerm_api_management_subscription.this.id
}

output "primary_key" {
  value     = azurerm_api_management_subscription.this.primary_key
  sensitive = true
}

output "secondary_key" {
  value     = azurerm_api_management_subscription.this.secondary_key
  sensitive = true
}
