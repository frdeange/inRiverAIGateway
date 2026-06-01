variable "api_management_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "product_id" {
  type = string
}

variable "display_name" {
  type = string
}

variable "description" {
  type    = string
  default = null
}

variable "subscription_required" {
  type    = bool
  default = true
}

variable "approval_required" {
  type    = bool
  default = false
}

variable "published" {
  type    = bool
  default = true
}

variable "subscriptions_limit" {
  type    = number
  default = null
}

variable "api_names" {
  description = "List of API names (the `name` of the apim-api submodule) attached to this product."
  type        = list(string)
  default     = []
}

variable "group_names" {
  description = "List of APIM group names attached to this product."
  type        = list(string)
  default     = []
}

variable "policy_file" {
  description = "Path to product-level policy XML. Empty disables product policy."
  type        = string
  default     = ""
}
