variable "subscription_id" {
  type        = string
  description = "APIM subscription id (also used as the resource name)."
}

variable "api_management_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "display_name" {
  type = string
}

variable "state" {
  type    = string
  default = "active"
}

variable "allow_tracing" {
  type    = bool
  default = false
}

variable "api_id" {
  type        = string
  default     = null
  description = "Set to scope this subscription to a single API. Mutually exclusive with product_id."
}

variable "product_id" {
  type        = string
  default     = null
  description = "Set to scope this subscription to a single product. Mutually exclusive with api_id."
}
