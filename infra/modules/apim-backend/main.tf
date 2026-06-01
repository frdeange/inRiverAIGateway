resource "azurerm_api_management_backend" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  protocol            = var.protocol
  url                 = var.url
  description         = var.description
  resource_id         = var.resource_id

  tls {
    validate_certificate_chain = var.tls_validate_certificate_chain
    validate_certificate_name  = var.tls_validate_certificate_name
  }
}

# Circuit breaker rules require the newer (azapi) sub-resource shape;
# azurerm 4.x does not yet expose them on `azurerm_api_management_backend`.
resource "azapi_update_resource" "circuit_breaker" {
  count = length(var.circuit_breaker_rules) == 0 ? 0 : 1

  type        = "Microsoft.ApiManagement/service/backends@2024-05-01"
  resource_id = azurerm_api_management_backend.this.id

  body = {
    properties = {
      circuitBreaker = {
        rules = [
          for r in var.circuit_breaker_rules : {
            name             = r.name
            tripDuration     = r.trip_duration
            acceptRetryAfter = r.accept_retry_after
            failureCondition = {
              count    = r.failure.count
              interval = r.failure.interval
              statusCodeRanges = [
                {
                  min = r.failure.status_code_min
                  max = r.failure.status_code_max
                },
              ]
              errorReasons = []
            }
          }
        ]
      }
    }
  }
}
