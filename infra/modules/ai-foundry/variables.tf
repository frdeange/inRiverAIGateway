variable "name" {
  type        = string
  description = "Cognitive (AIServices) account name."
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "S0"
}

variable "local_auth_enabled" {
  description = "Whether to keep key-based (local) authentication enabled on the AIServices account."
  type        = bool
  default     = false
}

variable "allow_project_management" {
  description = "Enable AI Foundry projects on this AIServices account."
  type        = bool
  default     = true
}

variable "deployments" {
  description = "Map of model deployments. Key = deployment name."
  type = map(object({
    model_format    = string
    model_name      = string
    model_version   = string
    sku_name        = optional(string, "Standard")
    sku_capacity    = optional(number, 1)
    rai_policy_name = optional(string)
  }))
  default = {}
}

variable "rai_policies" {
  description = <<-EOT
    Map of custom Responsible AI policies. Key = policy name. `content_filters_raw`
    is passed straight to the azapi resource body; see Azure REST docs for shape.
  EOT
  type = map(object({
    mode                = optional(string, "Default")
    base_policy_name    = optional(string, "Microsoft.DefaultV2")
    content_filters_raw = any
  }))
  default = {}
}

variable "projects" {
  description = "Map of AI Foundry projects. Key = project name."
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
  }))
  default = {}
}

variable "defender_for_ai_enabled" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
