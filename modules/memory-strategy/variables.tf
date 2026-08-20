variable "memory_id" {
  description = "ID of the AgentCore Memory to extend."
  type        = string
}

variable "name" {
  description = "Memory Strategy name."
  type        = string
}

variable "type" {
  description = "Memory Strategy type."
  type        = string

  validation {
    condition     = contains(["SEMANTIC", "SUMMARIZATION", "USER_PREFERENCE", "EPISODIC", "CUSTOM"], var.type)
    error_message = "type must be SEMANTIC, SUMMARIZATION, USER_PREFERENCE, EPISODIC, or CUSTOM."
  }
}

variable "description" {
  description = "Memory Strategy description."
  type        = string
  default     = null
}

variable "namespace_template" {
  description = "Single namespace template for this strategy."
  type        = string
}

variable "custom_configuration" {
  description = "Configuration required for CUSTOM strategies and omitted for built-in strategies."
  type = object({
    type = string
    consolidation = optional(object({
      append_to_prompt = string
      model_id         = string
    }))
    extraction = optional(object({
      append_to_prompt = string
      model_id         = string
    }))
    reflection = optional(object({
      append_to_prompt    = string
      model_id            = string
      namespace_templates = set(string)
    }))
  })
  default = null
}

variable "reflection_namespace_templates" {
  description = "Optional reflection namespaces for an EPISODIC strategy."
  type        = set(string)
  default     = []
}
