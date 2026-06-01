variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku_name" {
  description = "APIM SKU tier (e.g. BasicV2, StandardV2, Premium)."
  type        = string
  default     = "BasicV2"
}

variable "sku_capacity" {
  type    = number
  default = 1
}

variable "publisher_email" {
  type = string
}

variable "publisher_name" {
  type = string
}

variable "min_api_version" {
  type    = string
  default = "2021-08-01"
}

###############################################################################
# Observability wiring
###############################################################################
variable "app_insights_id" {
  type        = string
  description = "App Insights resource id (used by the APIM Application Insights logger)."
}

variable "app_insights_instrumentation_key" {
  type      = string
  sensitive = true
}

variable "law_id" {
  type        = string
  description = "Log Analytics workspace id (used by the Azure Monitor diagnostic setting on APIM)."
}

###############################################################################
# Global policy XML file
###############################################################################
variable "global_policy_file" {
  type        = string
  default     = ""
  description = "Path to the global APIM policy XML. Empty = use bundled default in this module."
}

###############################################################################
# Named values
###############################################################################
variable "named_values" {
  description = "Map of named values. Key = name."
  type = map(object({
    display_name = string
    value        = optional(string)
    secret       = optional(bool, false)
    tags         = optional(list(string), [])
  }))
  default = {}
}

variable "named_value_secrets" {
  description = "Map of secret values, keyed by named-value name. Required for entries with secret=true."
  type        = map(string)
  default     = {}
  sensitive   = true
}

###############################################################################
# Groups & users
###############################################################################
variable "groups" {
  description = "Map of custom APIM groups. Key = group id."
  type = map(object({
    display_name = string
    description  = optional(string)
    type         = optional(string, "custom") # custom | external
  }))
  default = {}
}

variable "users" {
  description = "Map of APIM users. Key = user id."
  type = map(object({
    first_name = string
    last_name  = string
    email      = string
    state      = optional(string, "active")
    groups     = optional(list(string), []) # group ids defined in var.groups
  }))
  default = {}
}

###############################################################################
# Notifications (recipient emails per notification type)
###############################################################################
variable "notifications" {
  description = "Map of notification name -> list of recipient emails."
  type        = map(list(string))
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
