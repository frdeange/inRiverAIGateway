resource "azurerm_container_app_environment" "this" {
  name                       = var.name_env
  resource_group_name        = var.resource_group_name
  location                   = var.location
  log_analytics_workspace_id = var.log_analytics_workspace_id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Grant the environment's system-assigned identity AcrPull, so the
# Container App can pull from ACR via `system-environment` identity
# (matches the current Bicep export behaviour).
resource "azurerm_role_assignment" "env_acrpull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app_environment.this.identity[0].principal_id
}

resource "azurerm_container_app" "this" {
  name                         = var.name_app
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  registry {
    server   = var.acr_login_server
    identity = "system-environment"
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.name_app
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  ingress {
    external_enabled           = var.ingress_external
    target_port                = var.target_port
    transport                  = "auto"
    allow_insecure_connections = false

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = var.tags

  # CI/CD pushes new image tags. Avoid drift on every plan.
  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
    ]
  }

  depends_on = [azurerm_role_assignment.env_acrpull]
}
