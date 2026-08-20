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

variable "conditions" {
  description = "Optional path or IAM principal conditions. Each entry must configure exactly one matcher; an empty list creates an unconditional rule."
  type = list(object({
    match_paths = optional(object({
      any_of = list(string)
    }))
    match_principals = optional(object({
      any_of = list(object({
        arn      = string
        operator = optional(string, "StringEquals")
      }))
    }))
  }))
  default = []

  validation {
    condition = length(var.conditions) <= 2 && alltrue([
      for condition in var.conditions :
      (condition.match_paths == null ? 0 : 1) + (condition.match_principals == null ? 0 : 1) == 1
    ])
    error_message = "conditions accepts at most two entries, and each entry must configure exactly one of match_paths or match_principals."
  }

  validation {
    condition = alltrue(flatten([
      for condition in var.conditions : condition.match_principals == null ? [] : [
        for principal in condition.match_principals.any_of : contains(["StringEquals", "StringLike"], principal.operator)
      ]
    ]))
    error_message = "IAM principal operators must be StringEquals or StringLike."
  }
}

variable "region" {
  description = "AWS Region in which to manage the Gateway Rule. Defaults to the provider Region."
  type        = string
  default     = null
}

variable "timeouts" {
  description = "Optional create, update, and delete timeouts for the Gateway Rule."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
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
