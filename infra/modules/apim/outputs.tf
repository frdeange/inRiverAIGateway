output "id" {
  value = azurerm_api_management.this.id
}

output "name" {
  value = azurerm_api_management.this.name
}

output "gateway_url" {
  value = azurerm_api_management.this.gateway_url
}

output "principal_id" {
  value = azurerm_api_management.this.identity[0].principal_id
}

output "appi_logger_id" {
  value       = azurerm_api_management_logger.appi.id
  description = "Used by per-API diagnostic submodules."
}

output "resource_group_name" {
  value = var.resource_group_name
}
