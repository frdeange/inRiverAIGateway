variable "name_law" {
  type        = string
  description = "Log Analytics workspace name."
}

variable "name_appi" {
  type        = string
  description = "Application Insights component name."
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "law_retention_days" {
  type    = number
  default = 30
}

variable "law_sku" {
  type    = string
  default = "PerGB2018"
}

variable "app_insights_retention_days" {
  type    = number
  default = 90
}

variable "tags" {
  type    = map(string)
  default = {}
}
