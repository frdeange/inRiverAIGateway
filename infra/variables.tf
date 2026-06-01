###############################################################################
# Global identification
###############################################################################
variable "project" {
  description = "Project short code. Used as the first token of every resource name."
  type        = string
  default     = "iagw"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,7}$", var.project))
    error_message = "project must be 2-8 lowercase alphanumeric chars and start with a letter."
  }
}

variable "environment" {
  description = "Environment short code (dev|tst|prd)."
  type        = string
  default     = "prd"
  validation {
    condition     = contains(["dev", "tst", "prd"], var.environment)
    error_message = "environment must be one of: dev, tst, prd."
  }
}

variable "primary_location" {
  description = "Primary Azure region for the Resource Group, APIM, ACR, ACA, LAW and App Insights."
  type        = string
  default     = "swedencentral"
}

variable "extra_tags" {
  description = "Additional tags merged on top of the defaults computed in locals.tf."
  type        = map(string)
  default     = {}
}

variable "resource_group_name_override" {
  description = "Optional explicit RG name. If empty, derived from naming convention."
  type        = string
  default     = ""
}

###############################################################################
# Observability
###############################################################################
variable "law_retention_days" {
  description = "Log Analytics retention in days."
  type        = number
  default     = 30
}

variable "app_insights_retention_days" {
  description = "Application Insights retention in days."
  type        = number
  default     = 90
}

###############################################################################
# Container Registry
###############################################################################
variable "acr_sku" {
  description = "ACR SKU (Basic|Standard|Premium)."
  type        = string
  default     = "Standard"
}

variable "acr_admin_enabled" {
  description = "Enable ACR admin user. Keep false; ACA uses managed identity."
  type        = bool
  default     = false
}

###############################################################################
# Container Apps
###############################################################################
variable "aca_workload" {
  description = "Workload suffix for the Container App (e.g. 'mcp')."
  type        = string
  default     = "mcp"
}

variable "aca_image" {
  description = "Full image reference for the Container App. CI/CD may override."
  type        = string
  default     = "inriveraigwacr.azurecr.io/mcp-product-catalog:latest"
}

variable "aca_target_port" {
  description = "Container ingress target port. 0 means tcp/auto (matches current export)."
  type        = number
  default     = 8080
}

variable "aca_cpu" {
  type    = number
  default = 0.25
}

variable "aca_memory" {
  type    = string
  default = "0.5Gi"
}

variable "aca_scale_min" {
  type    = number
  default = 0
}

variable "aca_scale_max" {
  type    = number
  default = 10
}

###############################################################################
# AI Foundry (multi-region AIServices accounts)
###############################################################################
variable "ai_foundry_accounts" {
  description = <<-EOT
    Map of AI Foundry (Cognitive `kind=AIServices`) accounts. Key is a short
    region code (esp|frc|sec) used in the resource name suffix.
  EOT
  type = map(object({
    location = string
    sku_name = optional(string, "S0")

    local_auth_enabled       = optional(bool, false)
    allow_project_management = optional(bool, true)
    defender_for_ai_enabled  = optional(bool, false)

    # Map of model deployments. Key = deployment name.
    deployments = optional(map(object({
      model_format    = string # OpenAI | Microsoft | Meta | ...
      model_name      = string # gpt-4o, text-embedding-3-large, ...
      model_version   = string
      sku_name        = optional(string, "Standard")
      sku_capacity    = optional(number, 1)
      rai_policy_name = optional(string)
    })), {})

    # Map of custom RAI (content filter) policies. Key = policy name.
    rai_policies = optional(map(object({
      mode                = optional(string, "Default")
      base_policy_name    = optional(string, "Microsoft.DefaultV2")
      content_filters_raw = any # see module README
    })), {})

    # Map of AI Foundry projects. Key = project name.
    projects = optional(map(object({
      display_name = optional(string)
      description  = optional(string)
    })), {})
  }))
  default = {
    sec = {
      location = "swedencentral"
    }
    esp = {
      location = "spaincentral"
    }
    frc = {
      location = "francecentral"
    }
  }
}

###############################################################################
# APIM
###############################################################################
variable "apim_sku_name" {
  description = "APIM SKU + capacity. Format: '<sku>_<capacity>'. Current export: BasicV2_1."
  type        = string
  default     = "BasicV2_1"
}

variable "apim_publisher_email" {
  type    = string
  default = "admin@gpsazure.com"
}

variable "apim_publisher_name" {
  type    = string
  default = "inriver-aigw AI Gateway"
}

variable "apim_named_values" {
  description = "Map of named values. Mark sensitive ones with `secret=true` and pass value via secrets.auto.tfvars."
  type = map(object({
    display_name = string
    value        = optional(string)
    secret       = optional(bool, false)
    tags         = optional(list(string), [])
  }))
  default = {}
}

variable "apim_backends" {
  description = "Map of single-URL APIM backends. Key = backend name."
  type = map(object({
    protocol     = optional(string, "http")
    url          = string
    description  = optional(string)
    resource_id  = optional(string)
    tls_validate = optional(bool, true)

    circuit_breaker_rules = optional(list(object({
      name               = string
      trip_duration      = string # ISO-8601, e.g. "PT1M"
      accept_retry_after = optional(bool, false)
      failure = object({
        count           = number
        interval        = string # ISO-8601, e.g. "PT1M"
        status_code_min = number
        status_code_max = number
      })
    })), [])
  }))
  default = {}
}

variable "apim_backend_pools" {
  description = "Map of APIM 'Pool' backends (round-robin or priority over single backends). Key = pool backend name."
  type = map(object({
    description = optional(string)
    services = list(object({
      backend_name = string # references a key in var.apim_backends
      weight       = number
      priority     = optional(number) # 1..5; lower = preferred
    }))
  }))
  default = {}
}

variable "apim_apis" {
  description = "Map of APIs. See modules/apim-api/variables.tf for the full object shape."
  type        = any
  default     = {}
}

variable "apim_products" {
  description = "Map of products. See modules/apim-product/variables.tf for the full object shape."
  type        = any
  default     = {}
}

variable "apim_groups" {
  description = "Custom APIM groups (system groups administrators/developers/guests are skipped)."
  type = map(object({
    display_name = string
    description  = optional(string)
    type         = optional(string, "custom")
  }))
  default = {}
}

variable "apim_users" {
  description = "Custom APIM users (system user '1' is skipped)."
  type = map(object({
    first_name = string
    last_name  = string
    email      = string
    state      = optional(string, "active")
    groups     = optional(list(string), [])
  }))
  default = {}
}

variable "apim_notifications" {
  description = "Notification name → list of recipient emails."
  type        = map(list(string))
  default     = {}
}

variable "apim_subscriptions" {
  description = <<-EOT
    Map of APIM subscriptions. Key = subscription id.
    `scope_kind` is one of:
      - "api":     scope_target must reference a key from var.apim_apis
      - "product": scope_target must reference a key from var.apim_products
      - "all":     scope_target ignored (subscription to all APIs)
  EOT
  type = map(object({
    display_name  = string
    scope_kind    = string
    scope_target  = optional(string)
    state         = optional(string, "active")
    allow_tracing = optional(bool, false)
  }))
  default = {}
}

###############################################################################
# Sensitive (secrets.auto.tfvars)
###############################################################################
variable "apim_named_value_secrets" {
  description = "Map of secret named-value names to their values. Keys must match `apim_named_values` entries flagged secret=true."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "jwt_signing_key" {
  description = "JWT signing key used by APIM policies (was @secure() param in the Bicep export)."
  type        = string
  default     = ""
  sensitive   = true
}
