output "environment_id" {
  value = azurerm_container_app_environment.this.id
}

output "environment_name" {
  value = azurerm_container_app_environment.this.name
}

output "app_id" {
  value = azurerm_container_app.this.id
}

output "app_fqdn" {
  value = try(azurerm_container_app.this.latest_revision_fqdn, null)
}
