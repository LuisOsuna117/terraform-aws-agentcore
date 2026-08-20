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

variable "role_policy_arns" {
  description = "Managed policy ARNs to attach to the module-created Gateway role. Ignored when create_role is false."
  type        = set(string)
  default     = []
}

variable "role_policy_statements" {
  description = "Additional least-privilege IAM statements for the module-created Gateway role, for example Smithy services or credential providers."
  type = list(object({
    sid       = optional(string)
    effect    = optional(string, "Allow")
    actions   = set(string)
    resources = set(string)
    condition = optional(any)
  }))
  default = []
}

# ==============================================================================
# Authorizer
# ==============================================================================

variable "authorizer_type" {
  description = "Inbound authorizer: CUSTOM_JWT, AWS_IAM, AUTHENTICATE_ONLY, or NONE. Offloaded authorization modes must be protected by a Policy Engine or downstream authorization."
  type        = string
  default     = "AWS_IAM"

  validation {
    condition     = contains(["CUSTOM_JWT", "AWS_IAM", "AUTHENTICATE_ONLY", "NONE"], var.authorizer_type)
    error_message = "authorizer_type must be CUSTOM_JWT, AWS_IAM, AUTHENTICATE_ONLY, or NONE."
  }
}

variable "authorizer_configuration" {
  description = <<-EOT
    JWT authorizer configuration. Required when authorizer_type = "CUSTOM_JWT".
    Shape:
      {
        discovery_url            = string
        allowed_audience         = optional(set(string))
        allowed_clients          = optional(set(string))
        allowed_scopes           = optional(set(string))
        workload_identities      = optional(list(string))
        hosting_environment_arns = optional(list(string))
        custom_claims            = optional(set(object(...)))
        private_endpoint         = optional(object(...))
        private_endpoint_overrides = optional(list(object(...)))
      }
  EOT
  type = object({
    discovery_url            = string
    allowed_audience         = optional(set(string), [])
    allowed_clients          = optional(set(string), [])
    allowed_scopes           = optional(set(string), [])
    workload_identities      = optional(list(string), [])
    hosting_environment_arns = optional(list(string), [])
    custom_claims = optional(set(object({
      inbound_token_claim_name       = string
      inbound_token_claim_value_type = string
      claim_match_operator           = string
      match_value_string             = optional(string)
      match_value_string_list        = optional(set(string))
    })), [])
    private_endpoint = optional(object({
      managed_vpc_resource = optional(object({
        endpoint_ip_address_type = string
        subnet_ids               = set(string)
        vpc_identifier           = string
        routing_domain           = optional(string)
        security_group_ids       = optional(set(string), [])
        tags                     = optional(map(string), {})
      }))
      self_managed_lattice_resource = optional(object({
        resource_configuration_identifier = string
      }))
    }))
    private_endpoint_overrides = optional(list(object({
      domain = string
      private_endpoint = object({
        managed_vpc_resource = optional(object({
          endpoint_ip_address_type = string
          subnet_ids               = set(string)
          vpc_identifier           = string
          routing_domain           = optional(string)
          security_group_ids       = optional(set(string), [])
          tags                     = optional(map(string), {})
        }))
        self_managed_lattice_resource = optional(object({
          resource_configuration_identifier = string
        }))
      })
    })), [])
  })
  default = null

  validation {
    condition = var.authorizer_configuration == null ? true : alltrue([
      for claim in var.authorizer_configuration.custom_claims : (
        contains(["STRING", "STRING_ARRAY"], claim.inbound_token_claim_value_type) &&
        contains(["EQUALS", "CONTAINS", "CONTAINS_ANY"], claim.claim_match_operator) &&
        ((claim.match_value_string != null) != (claim.match_value_string_list != null)) &&
        (claim.claim_match_operator != "EQUALS" || claim.inbound_token_claim_value_type == "STRING") &&
        (!contains(["CONTAINS", "CONTAINS_ANY"], claim.claim_match_operator) || claim.inbound_token_claim_value_type == "STRING_ARRAY") &&
        (claim.claim_match_operator != "CONTAINS_ANY" || claim.match_value_string_list != null) &&
        (claim.claim_match_operator == "CONTAINS_ANY" || claim.match_value_string != null)
      )
    ])
    error_message = "Each JWT custom claim must use a compatible value type, operator, and exactly one match value shape."
  }

  validation {
    condition = var.authorizer_configuration == null ? true : (
      var.authorizer_configuration.private_endpoint == null ? true : (
        (var.authorizer_configuration.private_endpoint.managed_vpc_resource != null) !=
        (var.authorizer_configuration.private_endpoint.self_managed_lattice_resource != null)
      )
    )
    error_message = "authorizer_configuration.private_endpoint must configure exactly one managed or self-managed VPC resource."
  }

  validation {
    condition = var.authorizer_configuration == null ? true : alltrue([
      for override in var.authorizer_configuration.private_endpoint_overrides : (
        (override.private_endpoint.managed_vpc_resource != null) !=
        (override.private_endpoint.self_managed_lattice_resource != null)
      )
    ])
    error_message = "Each JWT private endpoint override must configure exactly one managed or self-managed VPC resource."
  }
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
    instructions               = optional(string)
    search_type                = optional(string)
    supported_versions         = optional(set(string), [])
    session_timeout_in_seconds = optional(number)
    enable_response_streaming  = optional(bool)
  })
  default = null
}

variable "policy_engine_configuration" {
  description = "Optional Policy Engine association for Gateway authorization."
  type = object({
    arn  = string
    mode = string
  })
  default = null

  validation {
    condition     = var.policy_engine_configuration == null ? true : contains(["LOG_ONLY", "ENFORCE"], var.policy_engine_configuration.mode)
    error_message = "policy_engine_configuration.mode must be LOG_ONLY or ENFORCE."
  }
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
  type        = list(string)
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

variable "region" {
  description = "AWS Region in which to manage the Gateway. Defaults to the provider Region."
  type        = string
  default     = null
}

variable "timeouts" {
  description = "Optional create, update, and delete timeouts for the Gateway."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

# ==============================================================================
# Tags
# ==============================================================================

variable "tags" {
  description = "Map of tags to apply to the gateway resource."
  type        = map(string)
  default     = {}
}
