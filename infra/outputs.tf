output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "apim_gateway_url" {
  value = module.apim.gateway_url
}

output "apim_principal_id" {
  value = module.apim.principal_id
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "aca_app_fqdn" {
  value = module.container_apps.app_fqdn
}

output "log_analytics_workspace_id" {
  value = module.observability.log_analytics_workspace_id
}

output "application_insights_id" {
  value = module.observability.application_insights_id
}

output "ai_foundry_endpoints" {
  value = { for k, m in module.ai_foundry : k => m.endpoint }
}

output "ai_foundry_principal_ids" {
  value = { for k, m in module.ai_foundry : k => m.principal_id }
}
