variable "name" {
  description = "Name of the AgentCore Code Interpreter."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,47}$", var.name))
    error_message = "name must start with a letter, be at most 48 characters, and contain only letters, numbers, or underscores."
  }
}

variable "description" {
  description = "Human-readable description of the Code Interpreter."
  type        = string
  default     = "Managed by terraform-aws-agentcore."
}

variable "execution_role_arn" {
  description = "ARN of the IAM role assumed by the Code Interpreter. Required for SANDBOX mode."
  type        = string
  default     = null
}

variable "network_mode" {
  description = "Network mode for the Code Interpreter. Valid values: PUBLIC, SANDBOX, VPC."
  type        = string
  default     = "SANDBOX"

  validation {
    condition     = contains(["PUBLIC", "SANDBOX", "VPC"], var.network_mode)
    error_message = "network_mode must be one of: PUBLIC, SANDBOX, VPC."
  }
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for VPC mode."
  type        = list(string)
  default     = []
}

variable "vpc_subnet_ids" {
  description = "Subnet IDs for VPC mode."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the Code Interpreter."
  type        = map(string)
  default     = {}
}

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = var.network_mode != "SANDBOX" || var.execution_role_arn != null
      error_message = "execution_role_arn must be provided when network_mode = \"SANDBOX\"."
    }

    precondition {
      condition     = var.network_mode != "VPC" || (length(var.vpc_security_group_ids) > 0 && length(var.vpc_subnet_ids) > 0)
      error_message = "vpc_security_group_ids and vpc_subnet_ids must both be non-empty when network_mode = \"VPC\"."
    }
  }
}
