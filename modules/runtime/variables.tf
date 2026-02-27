variable "runtime_name" {
  description = "Resolved name for the AgentCore runtime (hyphens already converted to underscores)."
  type        = string
}

variable "description" {
  description = "Human-readable description of the runtime."
  type        = string
  default     = "Managed by terraform-aws-agentcore."
}

variable "execution_role_arn" {
  description = "ARN of the IAM execution role the runtime assumes."
  type        = string
}

variable "image_uri" {
  description = "Full container image URI (including tag) to deploy to the runtime."
  type        = string
}

variable "network_mode" {
  description = "Network mode — PUBLIC or PRIVATE."
  type        = string
  default     = "PUBLIC"
}

variable "environment_variables" {
  description = "Environment variables injected into the runtime process."
  type        = map(string)
  default     = {}
}
