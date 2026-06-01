# APIM "pool" backends are not exposed by azurerm_api_management_backend.
# We create them via azapi against the same ARM type.

resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/service/backends@2024-05-01"
  parent_id = var.apim_id
  name      = var.name

  body = {
    properties = {
      description = var.description
      type        = "Pool"
      pool = {
        services = [
          for s in var.services : merge(
            {
              id     = s.backend_id
              weight = s.weight
            },
            s.priority == null ? {} : { priority = s.priority },
          )
        ]
      }
    }
  }

  response_export_values = ["id", "name"]
}
