variable "name" {
  description = "Base name for the policy engine and policies."
  type        = string
}

variable "create_policy_engine" {
  description = "Whether to create a policy engine. Set false for resource-policy-only use or to attach policies to policy_engine_id."
  type        = bool
  default     = true
}

variable "policy_engine_id" {
  description = "Existing policy engine ID. Required when policies are provided and create_policy_engine is false."
  type        = string
  default     = null
}

variable "description" {
  description = "Description for the module-created policy engine."
  type        = string
  default     = null
}

variable "encryption_key_arn" {
  description = "Optional customer-managed KMS key ARN for the policy engine."
  type        = string
  default     = null
}

variable "policies" {
  description = "Cedar policies keyed by a stable caller-defined name. Statements are passed through without transformation."
  type = map(object({
    name            = optional(string)
    description     = optional(string)
    cedar_statement = string
    validation_mode = optional(string, "FAIL_ON_ANY_FINDINGS")
  }))
  default = {}
}

variable "resource_policies" {
  description = "AgentCore resource policies keyed by a stable caller-defined name. Policy JSON is passed through without transformation."
  type = map(object({
    resource_arn = string
    policy       = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to the policy engine."
  type        = map(string)
  default     = {}
}
