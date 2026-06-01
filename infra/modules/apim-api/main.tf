###############################################################################
# API definition
###############################################################################
resource "azurerm_api_management_api" "this" {
  name                = var.name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  revision            = var.revision

  display_name          = var.display_name
  path                  = var.path
  protocols             = var.protocols
  service_url           = var.service_url
  subscription_required = var.subscription_required

  subscription_key_parameter_names {
    header = var.subscription_key_header_name
    query  = var.subscription_key_query_param_name
  }

  dynamic "import" {
    for_each = var.import_format == null ? [] : [1]
    content {
      content_format = var.import_format
      content_value  = var.import_content
    }
  }
}

###############################################################################
# Operations (only when not importing OpenAPI)
###############################################################################
resource "azurerm_api_management_api_operation" "this" {
  for_each = var.import_format == null ? var.operations : {}

  operation_id        = each.key
  api_name            = azurerm_api_management_api.this.name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  display_name        = each.value.display_name
  method              = each.value.method
  url_template        = each.value.url_template
  description         = each.value.description

  dynamic "template_parameter" {
    for_each = each.value.template_parameters
    content {
      name        = template_parameter.value.name
      type        = template_parameter.value.type
      required    = template_parameter.value.required
      description = template_parameter.value.description
    }
  }
}

###############################################################################
# Per-operation policies
###############################################################################
resource "azurerm_api_management_api_operation_policy" "this" {
  for_each = {
    for k, v in var.operations :
    k => v
    if try(v.policy_file, "") != ""
  }

  api_name            = azurerm_api_management_api.this.name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  operation_id        = azurerm_api_management_api_operation.this[each.key].operation_id
  xml_content         = file(each.value.policy_file)
}

###############################################################################
# API-level policy
###############################################################################
resource "azurerm_api_management_api_policy" "this" {
  count = var.policy_file == "" ? 0 : 1

  api_name            = azurerm_api_management_api.this.name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  xml_content         = file(var.policy_file)
}

###############################################################################
# Per-API diagnostic settings to App Insights
###############################################################################
resource "azurerm_api_management_api_diagnostic" "appi" {
  count = var.enable_appi_diagnostic ? 1 : 0

  identifier               = "applicationinsights"
  resource_group_name      = var.resource_group_name
  api_management_name      = var.api_management_name
  api_name                 = azurerm_api_management_api.this.name
  api_management_logger_id = var.appi_logger_id

  sampling_percentage       = var.appi_sampling_percentage
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
