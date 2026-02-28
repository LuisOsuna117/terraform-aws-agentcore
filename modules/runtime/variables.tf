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

# ==============================================================================
# Network
# ==============================================================================

variable "network_mode" {
  description = "Network mode for the AgentCore runtime. Valid values: PUBLIC, VPC."
  type        = string
  default     = "PUBLIC"

  validation {
    condition     = contains(["PUBLIC", "VPC"], var.network_mode)
    error_message = "network_mode must be either \"PUBLIC\" or \"VPC\"."
  }
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for VPC mode. Required when network_mode = \"VPC\"."
  type        = list(string)
  default     = []
}

variable "vpc_subnet_ids" {
  description = "Subnet IDs for VPC mode. Required when network_mode = \"VPC\"."
  type        = list(string)
  default     = []
}

# ==============================================================================
# Authorizer
# ==============================================================================

variable "authorizer_discovery_url" {
  description = "OIDC discovery URL for JWT authorisation (must end with /.well-known/openid-configuration). When null, no authorizer is attached."
  type        = string
  default     = null
}

variable "authorizer_allowed_audience" {
  description = "Set of allowed JWT audience values. Ignored when authorizer_discovery_url is null."
  type        = list(string)
  default     = []
}

variable "authorizer_allowed_clients" {
  description = "Set of allowed client IDs for JWT token validation. Ignored when authorizer_discovery_url is null."
  type        = list(string)
  default     = []
}

# ==============================================================================
# Lifecycle
# ==============================================================================

variable "idle_runtime_session_timeout" {
  description = "Idle session timeout in seconds. When null, the service default applies."
  type        = number
  default     = null
}

variable "max_lifetime" {
  description = "Maximum instance lifetime in seconds. When null, the service default applies."
  type        = number
  default     = null
}

# ==============================================================================
# Protocol
# ==============================================================================

variable "server_protocol" {
  description = "Server protocol for the runtime. Valid values: HTTP, MCP, A2A. When null, the service default (HTTP) applies."
  type        = string
  default     = null

  validation {
    condition     = var.server_protocol == null || contains(["HTTP", "MCP", "A2A"], var.server_protocol)
    error_message = "server_protocol must be one of: HTTP, MCP, A2A."
  }
}

variable "request_header_allowlist" {
  description = "List of HTTP request headers to pass through to the runtime. When empty, no additional headers are forwarded."
  type        = list(string)
  default     = []
}

# ==============================================================================
# Environment
# ==============================================================================

variable "environment_variables" {
  description = "Environment variables injected into the runtime process."
  type        = map(string)
  default     = {}
}
