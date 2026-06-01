variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku" {
  type    = string
  default = "Standard"
}

variable "admin_enabled" {
  type    = bool
  default = false
}

variable "scope_maps" {
  description = "Optional map of scope maps. Key = name."
  type = map(object({
    description = optional(string)
    actions     = list(string)
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
