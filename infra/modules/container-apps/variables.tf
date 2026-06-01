variable "name_env" {
  type = string
}

variable "name_app" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "acr_id" {
  description = "ACR resource id. Used to grant AcrPull to the environment's managed identity."
  type        = string
}

variable "acr_login_server" {
  type = string
}

variable "image" {
  description = "Full container image reference (e.g. acrname.azurecr.io/repo:tag)."
  type        = string
}

variable "target_port" {
  type    = number
  default = 8080
}

variable "cpu" {
  type    = number
  default = 0.25
}

variable "memory" {
  type    = string
  default = "0.5Gi"
}

variable "min_replicas" {
  type    = number
  default = 0
}

variable "max_replicas" {
  type    = number
  default = 10
}

variable "env_vars" {
  description = "Map of non-secret env vars to inject into the container."
  type        = map(string)
  default     = {}
}

variable "ingress_external" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
