###############################################################################
# APIM service
###############################################################################
resource "azurerm_api_management" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_email     = var.publisher_email
  publisher_name      = var.publisher_name
  sku_name            = "${var.sku_name}_${var.sku_capacity}"
  min_api_version     = var.min_api_version

  identity {
    type = "SystemAssigned"
  }

  security {
    backend_ssl30_enabled  = false
    backend_tls10_enabled  = false
    backend_tls11_enabled  = false
    frontend_ssl30_enabled = false
    frontend_tls10_enabled = false
    frontend_tls11_enabled = false
  }

  tags = var.tags
}

###############################################################################
# Global policy
###############################################################################
resource "azurerm_api_management_policy" "global" {
  api_management_id = azurerm_api_management.this.id
  xml_content       = file(coalesce(var.global_policy_file, "${path.module}/policies/global.xml"))
}

###############################################################################
# Application Insights logger + Azure Monitor diagnostic setting
###############################################################################
resource "azurerm_api_management_logger" "appi" {
  name                = "applicationinsights"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  resource_id         = var.app_insights_id

  application_insights {
    instrumentation_key = var.app_insights_instrumentation_key
  }
}

resource "azurerm_api_management_diagnostic" "appi" {
  identifier               = "applicationinsights"
  resource_group_name      = var.resource_group_name
  api_management_name      = azurerm_api_management.this.name
  api_management_logger_id = azurerm_api_management_logger.appi.id

  sampling_percentage       = 100
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "information"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes     = 0
    headers_to_log = []
  }
  frontend_response {
    body_bytes     = 0
    headers_to_log = []
  }
  backend_request {
    body_bytes     = 0
    headers_to_log = []
  }
  backend_response {
    body_bytes     = 0
    headers_to_log = []
  }
}

resource "azurerm_monitor_diagnostic_setting" "law" {
  name                       = "to-law"
  target_resource_id         = azurerm_api_management.this.id
  log_analytics_workspace_id = var.law_id

  enabled_log { category_group = "allLogs" }
  enabled_metric { category = "AllMetrics" }
}

###############################################################################
# Named values
###############################################################################
resource "azurerm_api_management_named_value" "this" {
  for_each = var.named_values

  name                = each.key
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.this.name
  display_name        = each.value.display_name
  secret              = coalesce(each.value.secret, false)
  value               = coalesce(each.value.secret, false) ? lookup(var.named_value_secrets, each.key, null) : each.value.value
  tags                = each.value.tags
}

###############################################################################
# Groups & users
###############################################################################
resource "azurerm_api_management_group" "this" {
  for_each = var.groups

  name                = each.key
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.this.name
  display_name        = each.value.display_name
  description         = each.value.description
  type                = each.value.type
}

resource "azurerm_api_management_user" "this" {
  for_each = var.users

  user_id             = each.key
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.this.name
  first_name          = each.value.first_name
  last_name           = each.value.last_name
  email               = each.value.email
  state               = each.value.state
}

# Flatten user→group memberships into a single set of (user, group) pairs.
locals {
  user_group_pairs = flatten([
    for uid, u in var.users : [
      for g in u.groups : { user_id = uid, group_id = g }
    ]
  ])
}

resource "azurerm_api_management_group_user" "this" {
  for_each = {
    for p in local.user_group_pairs :
    "${p.user_id}__${p.group_id}" => p
  }

  user_id             = azurerm_api_management_user.this[each.value.user_id].user_id
  group_name          = azurerm_api_management_group.this[each.value.group_id].name
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.this.name
}

###############################################################################
# Notification recipient emails
###############################################################################
locals {
  notification_email_pairs = flatten([
    for n, emails in var.notifications : [
      for e in emails : { notification = n, email = e }
    ]
  ])
}

resource "azurerm_api_management_notification_recipient_email" "this" {
  for_each = {
    for p in local.notification_email_pairs :
    "${p.notification}__${p.email}" => p
  }

  api_management_id = azurerm_api_management.this.id
  notification_type = each.value.notification
  email             = each.value.email
}
