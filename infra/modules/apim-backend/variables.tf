variable "name" {
  type = string
}

variable "api_management_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "protocol" {
  type    = string
  default = "http"
}

variable "url" {
  type = string
}

variable "description" {
  type    = string
  default = null
}

variable "resource_id" {
  description = "Optional: ARM resource id of the backing service (e.g. AIServices account id for AOAI backends)."
  type        = string
  default     = null
}

variable "tls_validate_certificate_chain" {
  type    = bool
  default = true
}

variable "tls_validate_certificate_name" {
  type    = bool
  default = true
}

variable "circuit_breaker_rules" {
  description = <<-EOT
    Optional list of circuit breaker rules. Each rule trips after
    `failure.count` matching responses within `failure.interval`, stays open for
    `trip_duration`, and optionally respects the `Retry-After` response header.
  EOT
  type = list(object({
    name               = string
    trip_duration      = string # ISO-8601, e.g. "PT1M"
    accept_retry_after = optional(bool, false)
    failure = object({
      count           = number
      interval        = string # ISO-8601, e.g. "PT1M"
      status_code_min = number
      status_code_max = number
    })
  }))
  default = []
}
