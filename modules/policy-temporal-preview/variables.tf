variable "policy_engine_id" {
  description = "Identifier of the existing AgentCore Policy Engine that owns these temporal policies."
  type        = string
}

variable "policies" {
  description = "Dogwood temporal policies keyed by a stable caller-defined name. Statements are passed through without transformation."
  type = map(object({
    name             = optional(string)
    description      = optional(string)
    statement        = string
    enforcement_mode = optional(string, "LOG_ONLY")
    validation_mode  = optional(string, "FAIL_ON_ANY_FINDINGS")
  }))
  default = {}

  validation {
    condition = alltrue([
      for policy in values(var.policies) : contains(["LOG_ONLY", "ACTIVE"], policy.enforcement_mode)
    ])
    error_message = "Each enforcement_mode must be LOG_ONLY or ACTIVE."
  }

  validation {
    condition = alltrue([
      for policy in values(var.policies) : contains(["FAIL_ON_ANY_FINDINGS", "IGNORE_ALL_FINDINGS"], policy.validation_mode)
    ])
    error_message = "Each validation_mode must be FAIL_ON_ANY_FINDINGS or IGNORE_ALL_FINDINGS."
  }
}
