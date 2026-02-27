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
  description = "Protocol type for the gateway. Currently only \"MCP\" is supported."
  type        = string
  default     = "MCP"

  validation {
    condition     = contains(["MCP"], var.protocol_type)
    error_message = "protocol_type must be \"MCP\"."
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
# Encryption & Advanced
# ==============================================================================

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt gateway data. When null, AWS-managed encryption is used."
  type        = string
  default     = null
}

variable "exception_level" {
  description = "Exception detail level exposed via the gateway. Valid values: INFO, WARN, ERROR."
  type        = string
  default     = null

  validation {
    condition     = var.exception_level == null || contains(["INFO", "WARN", "ERROR"], var.exception_level)
    error_message = "exception_level must be one of INFO, WARN, or ERROR."
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
