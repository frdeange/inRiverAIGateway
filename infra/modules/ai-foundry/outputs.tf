output "id" {
  value = azurerm_cognitive_account.this.id
}

output "name" {
  value = azurerm_cognitive_account.this.name
}

output "endpoint" {
  value = azurerm_cognitive_account.this.endpoint
}

output "principal_id" {
  value = azurerm_cognitive_account.this.identity[0].principal_id
}

output "primary_key" {
  value     = azurerm_cognitive_account.this.primary_access_key
  sensitive = true
}

output "deployment_ids" {
  value = { for k, d in azurerm_cognitive_deployment.this : k => d.id }
}

output "project_ids" {
  value = { for k, p in azapi_resource.project : k => p.id }
}
