variable "gateway_identifier" {
  description = "ID of the AgentCore Gateway that owns this rule."
  type        = string
}

variable "priority" {
  description = "Rule evaluation priority."
  type        = number
}

variable "description" {
  description = "Gateway Rule description."
  type        = string
  default     = null
}

variable "paths" {
  description = "Request paths matched by this rule."
  type        = list(string)
}

variable "iam_principals" {
  description = "Optional IAM principal ARNs matched by this rule."
  type        = set(string)
  default     = []
}

variable "static_target_name" {
  description = "Static Gateway target name. Exactly one action input must be configured."
  type        = string
  default     = null
}

variable "weighted_targets" {
  description = "Weighted Gateway target routes. Exactly one action input must be configured."
  type = list(object({
    name        = string
    target_name = string
    weight      = number
    description = optional(string)
    metadata    = optional(map(string), {})
  }))
  default = []
}

variable "static_configuration_bundle" {
  description = "Static Configuration Bundle override. Exactly one action input must be configured."
  type = object({
    bundle_arn     = string
    bundle_version = string
  })
  default = null
}

variable "weighted_configuration_bundles" {
  description = "Weighted Configuration Bundle overrides. Exactly one action input must be configured."
  type = list(object({
    name           = string
    weight         = number
    bundle_arn     = string
    bundle_version = string
    description    = optional(string)
    metadata       = optional(map(string), {})
  }))
  default = []
}
