# ==============================================================================
# Core
# ==============================================================================

variable "name" {
  description = "Name of the AgentCore Gateway."
  type        = string
}

variable "description" {
  description = "Human-readable description of the gateway."
  type        = string
  default     = null
}

# ==============================================================================
# IAM — Gateway Role
# ==============================================================================

variable "create_role" {
  description = "When true, creates an IAM role with the minimal trust policy for the gateway. Set to false and supply role_arn to reuse an existing role."
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "ARN of an existing IAM role for the gateway. Required when create_role = false."
  type        = string
  default     = null

  validation {
    condition     = var.role_arn == null || can(regex("^arn:aws[^:]*:iam::[0-9]{12}:role/.+", var.role_arn))
    error_message = "role_arn must be a valid IAM role ARN."
  }
}

# ==============================================================================
# Authorizer
# ==============================================================================

variable "authorizer_type" {
  description = "Type of request authorizer. \"CUSTOM_JWT\" requires authorizer_configuration. \"AWS_IAM\" uses AWS Signature Version 4."
  type        = string
  default     = "AWS_IAM"

  validation {
    condition     = contains(["CUSTOM_JWT", "AWS_IAM"], var.authorizer_type)
    error_message = "authorizer_type must be either \"CUSTOM_JWT\" or \"AWS_IAM\"."
  }
}

variable "authorizer_configuration" {
  description = <<-EOT
    JWT authorizer configuration. Required when authorizer_type = "CUSTOM_JWT".
    Shape:
      {
        discovery_url    = string                    # OIDC discovery URL (must end with /.well-known/openid-configuration)
        allowed_audience = optional(list(string))   # Allowed JWT audience values
        allowed_clients  = optional(list(string))   # Allowed JWT client IDs
      }
  EOT
  type = object({
    discovery_url    = string
    allowed_audience = optional(list(string), [])
    allowed_clients  = optional(list(string), [])
  })
  default = null
}

# ==============================================================================
# Protocol
# ==============================================================================

variable "protocol_type" {
  description = "Optional gateway aggregation protocol. Set to \"MCP\" for MCP aggregation, or null for general HTTP targets such as AgentCore Runtime agents. When null and an MCP target is configured, the module infers \"MCP\"."
  type        = string
  default     = null

  validation {
    condition     = var.protocol_type == null ? true : var.protocol_type == "MCP"
    error_message = "protocol_type must be \"MCP\" or null."
  }
}

variable "protocol_configuration" {
  description = <<-EOT
    MCP protocol configuration. Optional.
    Shape:
      {
        instructions       = optional(string)       # Instructions for the MCP handler
        search_type        = optional(string)       # "SEMANTIC" or "HYBRID"
        supported_versions = optional(list(string)) # e.g. ["2025-03-26"]
      }
  EOT
  type = object({
    instructions       = optional(string)
    search_type        = optional(string)
    supported_versions = optional(list(string), [])
  })
  default = null
}

# ==============================================================================
# Interceptors
# ==============================================================================

variable "interceptor_configurations" {
  description = <<-EOT
    List of interceptor configurations (min 0, max 2). Each entry shape:
      {
        interception_points  = list(string)          # "REQUEST" and/or "RESPONSE"
        lambda_arn           = string                # ARN of the interceptor Lambda
        pass_request_headers = optional(bool, false) # Forward request headers to Lambda
      }
  EOT
  type = list(object({
    interception_points  = list(string)
    lambda_arn           = string
    pass_request_headers = optional(bool, false)
  }))
  default = []

  validation {
    condition     = length(var.interceptor_configurations) <= 2
    error_message = "At most 2 interceptor_configurations may be specified."
  }
}

# ==============================================================================
# Gateway Targets
# ==============================================================================

variable "targets" {
  description = "Map of general Gateway Targets. Each entry uses the native target_configuration, credential, metadata, private endpoint, and timeout shapes."
  type        = any
  default     = {}

  validation {
    condition = can(keys(var.targets)) && alltrue([
      for target in values(var.targets) : try(target.name, null) == null || can(regex("^([0-9a-zA-Z][-]?){1,100}$", target.name))
    ])
    error_message = "Each Gateway Target name must contain only letters, numbers, and hyphens, start with a letter or number, and be at most 100 characters."
  }
}

variable "runtime_invoke_arns" {
  description = "Additional AgentCore Runtime ARNs the module-created Gateway role may invoke. HTTP Runtime target ARNs are inferred automatically."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.runtime_invoke_arns : can(regex("^arn:aws[^:]*:bedrock-agentcore:[a-z0-9-]+:[0-9]{12}:(runtime|agent)/.+", arn))
    ])
    error_message = "Each runtime_invoke_arns value must be a valid Bedrock AgentCore Runtime ARN."
  }
}

# ==============================================================================
# Encryption & Advanced
# ==============================================================================

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt gateway data. When null, AWS-managed encryption is used."
  type        = string
  default     = null
}

variable "exception_level" {
  description = "Exception detail level exposed via the gateway. AgentCore currently accepts only DEBUG."
  type        = string
  default     = null

  validation {
    condition     = var.exception_level == null ? true : var.exception_level == "DEBUG"
    error_message = "exception_level must be DEBUG or null."
  }
}

# ==============================================================================
# Tags
# ==============================================================================

variable "tags" {
  description = "Map of tags to apply to the gateway resource."
  type        = map(string)
  default     = {}
}
