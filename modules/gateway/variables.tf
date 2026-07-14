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
  description = <<-EOT
    Map of Gateway Targets. Each entry selects its target type explicitly.

    Shape:
      {
        target_type               = string               # "MCP" or "AGENT"
        name                      = optional(string)     # Target name; defaults to the map key
        description               = optional(string)
        endpoint                  = optional(string)     # MCP HTTPS server endpoint
        agent_runtime_arn         = optional(string)     # Runtime ARN for MCP or AGENT targets
        qualifier                 = optional(string)     # Runtime qualifier; defaults to "DEFAULT"
        schema                    = optional(object({    # Optional AGENT API schema
          inline_payload          = optional(string)
          s3                      = optional(object({
            uri                   = string
            bucket_owner_account_id = optional(string)
          }))
        }))
        allowed_query_parameters  = optional(list(string))
        allowed_request_headers   = optional(list(string))
        allowed_response_headers  = optional(list(string))
      }

    MCP targets must provide exactly one of endpoint or agent_runtime_arn. AGENT
    targets must provide agent_runtime_arn and are attached to a gateway whose
    effective protocol_type is null.
  EOT
  type = map(object({
    target_type       = string
    name              = optional(string)
    description       = optional(string)
    endpoint          = optional(string)
    agent_runtime_arn = optional(string)
    qualifier         = optional(string, "DEFAULT")
    schema = optional(object({
      inline_payload = optional(string)
      s3 = optional(object({
        uri                     = string
        bucket_owner_account_id = optional(string)
      }))
    }))
    allowed_query_parameters = optional(list(string), [])
    allowed_request_headers  = optional(list(string), [])
    allowed_response_headers = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for target in values(var.targets) : contains(["MCP", "AGENT"], upper(target.target_type))
    ])
    error_message = "Each targets entry target_type must be either \"MCP\" or \"AGENT\"."
  }

  validation {
    condition = alltrue([
      for target in values(var.targets) :
      upper(target.target_type) != "MCP" || length(compact([
        try(trimspace(target.endpoint), ""),
        try(trimspace(target.agent_runtime_arn), ""),
      ])) == 1
    ])
    error_message = "Each MCP targets entry must provide exactly one of endpoint or agent_runtime_arn."
  }

  validation {
    condition = alltrue([
      for target in values(var.targets) :
      upper(target.target_type) != "AGENT" || (
        try(trimspace(target.agent_runtime_arn), "") != "" &&
        try(trimspace(target.endpoint), "") == ""
      )
    ])
    error_message = "Each AGENT targets entry must provide agent_runtime_arn and must not set endpoint."
  }

  validation {
    condition = alltrue([
      for target in values(var.targets) :
      try(trimspace(target.endpoint), "") == "" || can(regex("^https://", trimspace(target.endpoint)))
    ])
    error_message = "Each explicit target endpoint must start with https://."
  }

  validation {
    condition = alltrue([
      for target in values(var.targets) :
      try(trimspace(target.agent_runtime_arn), "") == "" || can(regex("^arn:aws[^:]*:bedrock-agentcore:[a-z0-9-]+:[0-9]{12}:(runtime|agent)/.+", trimspace(target.agent_runtime_arn)))
    ])
    error_message = "Each agent_runtime_arn must be a valid Bedrock AgentCore Runtime ARN."
  }

  validation {
    condition = alltrue([
      for target in values(var.targets) :
      target.name == null || can(regex("^([0-9a-zA-Z][-]?){1,100}$", target.name))
    ])
    error_message = "Each target name must contain only letters, numbers, and hyphens, start with a letter or number, and be at most 100 characters."
  }

  validation {
    condition = alltrue([
      for target in values(var.targets) :
      target.schema == null || length(compact([
        try(trimspace(target.schema.inline_payload), ""),
        try(trimspace(target.schema.s3.uri), ""),
      ])) == 1
    ])
    error_message = "Each target schema must provide exactly one of inline_payload or s3."
  }

  validation {
    condition = alltrue([
      for target in values(var.targets) : target.schema == null || upper(target.target_type) == "AGENT"
    ])
    error_message = "The schema attribute is only supported for AGENT targets."
  }
}

variable "mcp_targets" {
  description = <<-EOT
    Deprecated compatibility alias for MCP Gateway Targets. Prefer targets with
    target_type = "MCP" for new configurations.
    Each map key is used as the target name unless name is set.

    Shape:
      {
        name                     = optional(string)       # Target name; defaults to the map key
        description              = optional(string)       # Target description
        endpoint                 = optional(string)       # Explicit HTTPS MCP server endpoint
        agent_runtime_arn        = optional(string)       # AgentCore Runtime ARN; endpoint and SigV4 auth are derived
        qualifier                = optional(string)       # AgentCore Runtime qualifier; defaults to "DEFAULT"
        allowed_query_parameters = optional(list(string)) # Query parameters propagated to the target
        allowed_request_headers  = optional(list(string)) # Request headers propagated to the target
        allowed_response_headers = optional(list(string)) # Response headers propagated from the target
      }

    Exactly one of endpoint or agent_runtime_arn must be provided for each target.
  EOT
  type = map(object({
    name                     = optional(string)
    description              = optional(string)
    endpoint                 = optional(string)
    agent_runtime_arn        = optional(string)
    qualifier                = optional(string, "DEFAULT")
    allowed_query_parameters = optional(list(string), [])
    allowed_request_headers  = optional(list(string), [])
    allowed_response_headers = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for target in values(var.mcp_targets) :
      length(compact([
        try(trimspace(target.endpoint), ""),
        try(trimspace(target.agent_runtime_arn), ""),
      ])) == 1
    ])
    error_message = "Each mcp_targets entry must provide exactly one of endpoint or agent_runtime_arn."
  }

  validation {
    condition = alltrue([
      for target in values(var.mcp_targets) :
      try(trimspace(target.endpoint), "") == "" || can(regex("^https://", trimspace(target.endpoint)))
    ])
    error_message = "Each explicit MCP target endpoint must start with https://."
  }

  validation {
    condition = alltrue([
      for target in values(var.mcp_targets) :
      try(trimspace(target.agent_runtime_arn), "") == "" || can(regex("^arn:aws[^:]*:bedrock-agentcore:[a-z0-9-]+:[0-9]{12}:(runtime|agent)/.+", trimspace(target.agent_runtime_arn)))
    ])
    error_message = "Each agent_runtime_arn must be a valid Bedrock AgentCore Runtime ARN."
  }

  validation {
    condition = alltrue([
      for target in values(var.mcp_targets) :
      target.name == null || can(regex("^([0-9a-zA-Z][-]?){1,100}$", target.name))
    ])
    error_message = "Each MCP target name must contain only letters, numbers, and hyphens, start with a letter or number, and be at most 100 characters."
  }
}

variable "agent_runtime_target_keys" {
  description = "Plan-known MCP target keys that represent AgentCore Runtime targets. When null, keys are inferred from targets without an explicit endpoint."
  type        = set(string)
  default     = null
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
    condition     = var.exception_level == null ? true : contains(["INFO", "WARN", "ERROR"], var.exception_level)
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
