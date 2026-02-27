# ==============================================================================
# Core
# ==============================================================================

variable "name" {
  description = "Name of the AgentCore Memory resource."
  type        = string
}

variable "event_expiry_duration" {
  description = "Number of days after which memory events expire. Valid range: 7–365."
  type        = number

  validation {
    condition     = var.event_expiry_duration >= 7 && var.event_expiry_duration <= 365
    error_message = "event_expiry_duration must be between 7 and 365 days."
  }
}

variable "description" {
  description = "Human-readable description of the memory."
  type        = string
  default     = null
}

# ==============================================================================
# Encryption
# ==============================================================================

variable "encryption_key_arn" {
  description = "ARN of the KMS key used to encrypt memory data. When null, AWS-managed encryption is used."
  type        = string
  default     = null
}

# ==============================================================================
# IAM — Memory Execution Role
# ==============================================================================

variable "memory_execution_role_arn" {
  description = "ARN of the IAM role the memory service assumes. Required when using custom memory strategies with model processing. When null, the default service role is used."
  type        = string
  default     = null
}

# ==============================================================================
# Tags
# ==============================================================================

variable "tags" {
  description = "Map of tags to apply to the memory resource."
  type        = map(string)
  default     = {}
}
