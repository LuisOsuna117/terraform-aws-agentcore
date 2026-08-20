variable "name" {
  description = "Managed Harness name. Hyphens are normalized to underscores."
  type        = string
}

variable "execution_role_arn" {
  description = "IAM role assumed by the Managed Harness."
  type        = string
}

variable "image_uri" {
  description = "Optional container image URI for a custom Harness environment."
  type        = string
  default     = null
}

variable "model_id" {
  description = "Amazon Bedrock model ID used by the Harness."
  type        = string
}

variable "system_prompt" {
  description = "Harness system prompt. This value is sensitive in plans and state."
  type        = string
  sensitive   = true
}

variable "environment_variables" {
  description = "Environment variables for the Harness. Do not place credentials in this map."
  type        = map(string)
  default     = {}
}

variable "network_mode" {
  description = "Harness network mode: PUBLIC or VPC."
  type        = string
  default     = "PUBLIC"

  validation {
    condition     = contains(["PUBLIC", "VPC"], var.network_mode)
    error_message = "network_mode must be PUBLIC or VPC."
  }
}

variable "vpc_security_group_ids" {
  description = "Security groups used when network_mode is VPC."
  type        = set(string)
  default     = []
}

variable "vpc_subnet_ids" {
  description = "Subnets used when network_mode is VPC."
  type        = set(string)
  default     = []
}

variable "require_service_s3_endpoint" {
  description = "Whether VPC Harness networking requires an S3 service endpoint."
  type        = bool
  default     = false
}

variable "idle_runtime_session_timeout" {
  description = "Optional idle session timeout in seconds."
  type        = number
  default     = null
}

variable "max_lifetime" {
  description = "Optional maximum environment lifetime in seconds."
  type        = number
  default     = null
}

variable "allowed_tools" {
  description = "Tool names the Harness may invoke. Avoid wildcard entries for production usage."
  type        = list(string)
  default     = []
}

variable "max_iterations" {
  description = "Maximum agent-loop iterations per invocation."
  type        = number
  default     = 10
}

variable "max_tokens" {
  description = "Maximum model output tokens per iteration."
  type        = number
  default     = 8192
}

variable "timeout_seconds" {
  description = "Maximum Harness invocation duration in seconds."
  type        = number
  default     = 900
}

variable "temperature" {
  description = "Bedrock model temperature."
  type        = number
  default     = 0
}

variable "top_p" {
  description = "Bedrock model top-p value."
  type        = number
  default     = 1
}

variable "memory" {
  description = "Optional AgentCore Memory configuration. Memory is disabled when null."
  type = object({
    arn            = string
    actor_id       = optional(string)
    messages_count = optional(number)
    retrieval = optional(map(object({
      relevance_score = optional(number)
      strategy_id     = optional(string)
      top_k           = optional(number)
    })), {})
  })
  default = null
}

variable "jwt_authorizer" {
  description = "Optional CUSTOM_JWT authorizer configuration."
  type = object({
    discovery_url            = string
    allowed_audience         = optional(set(string), [])
    allowed_clients          = optional(set(string), [])
    allowed_scopes           = optional(set(string), [])
    workload_identities      = optional(list(string), [])
    hosting_environment_arns = optional(list(string), [])
  })
  default = null
}

variable "skills" {
  description = "Filesystem paths to Harness skill definitions."
  type        = set(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the Harness."
  type        = map(string)
  default     = {}
}
