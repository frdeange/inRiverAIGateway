variable "name" {
  type = string
}

variable "apim_id" {
  type        = string
  description = "Parent APIM service id."
}

variable "description" {
  type    = string
  default = null
}

variable "services" {
  description = <<-EOT
    List of member backends. `backend_id` must be the ARM id of an existing
    azurerm_api_management_backend in the same APIM.
    `priority` (1..5) is optional; lower = preferred.
  EOT
  type = list(object({
    backend_id = string
    weight     = number
    priority   = optional(number)
  }))
}
