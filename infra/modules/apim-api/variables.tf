variable "api_management_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "appi_logger_id" {
  type        = string
  description = "APIM Application Insights logger id (from the apim module output)."
}

variable "name" {
  description = "API id (path-safe slug)."
  type        = string
}

variable "display_name" {
  type = string
}

variable "path" {
  description = "URL suffix segment (e.g. 'openai')."
  type        = string
}

variable "protocols" {
  type    = list(string)
  default = ["https"]
}

variable "service_url" {
  type    = string
  default = null
}

variable "subscription_required" {
  type    = bool
  default = true
}

variable "subscription_key_header_name" {
  description = "Header name for the subscription key. Azure OpenAI APIs use 'api-key'."
  type        = string
  default     = "Ocp-Apim-Subscription-Key"
}

variable "subscription_key_query_param_name" {
  type    = string
  default = "subscription-key"
}

variable "revision" {
  type    = string
  default = "1"
}

variable "import_format" {
  description = "Optional OpenAPI/WSDL import format. One of: openapi, openapi+json, swagger-json, etc."
  type        = string
  default     = null
}

variable "import_content" {
  description = "OpenAPI/Swagger content (raw string). Used when import_format is set."
  type        = string
  default     = null
}

###############################################################################
# Manually-declared operations (when not using OpenAPI import)
###############################################################################
variable "operations" {
  description = "Map of API operations. Key = operation id."
  type = map(object({
    display_name = string
    method       = string
    url_template = string
    description  = optional(string)
    policy_file  = optional(string) # path to per-operation policy XML
    template_parameters = optional(list(object({
      name        = string
      type        = string
      required    = optional(bool, true)
      description = optional(string)
    })), [])
  }))
  default = {}
}

###############################################################################
# API-level policy (single XML file)
###############################################################################
variable "policy_file" {
  description = "Path to the per-API policy XML. Empty disables api-level policy."
  type        = string
  default     = ""
}

###############################################################################
# Per-API diagnostic settings to Application Insights
###############################################################################
variable "enable_appi_diagnostic" {
  type    = bool
  default = true
}

variable "appi_sampling_percentage" {
  type    = number
  default = 100
}
