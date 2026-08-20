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

variable "model" {
  description = "Exactly one Managed Harness model configuration."
  type = object({
    bedrock = optional(object({
      model_id    = string
      max_tokens  = optional(number)
      temperature = optional(number)
      top_p       = optional(number)
    }))
    openai = optional(object({
      model_id    = string
      api_key_arn = string
      max_tokens  = optional(number)
      temperature = optional(number)
      top_p       = optional(number)
    }))
    gemini = optional(object({
      model_id    = string
      api_key_arn = string
      max_tokens  = optional(number)
      temperature = optional(number)
      top_p       = optional(number)
      top_k       = optional(number)
    }))
  })

  validation {
    condition = length(compact([
      var.model.bedrock == null ? "" : "bedrock",
      var.model.openai == null ? "" : "openai",
      var.model.gemini == null ? "" : "gemini",
    ])) == 1
    error_message = "model must configure exactly one of bedrock, openai, or gemini."
  }
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
  sensitive   = true
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

variable "filesystems" {
  description = "Opt-in runtime filesystem mounts. Each entry configures exactly one storage type."
  type = list(object({
    session_storage = optional(object({
      mount_path = string
    }))
    s3_files_access_point = optional(object({
      access_point_arn = string
      mount_path       = string
    }))
    efs_access_point = optional(object({
      access_point_arn = string
      mount_path       = string
    }))
  }))
  default = []

  validation {
    condition = length(var.filesystems) <= 5 && alltrue([
      for filesystem in var.filesystems : length(compact([
        filesystem.session_storage == null ? "" : "session_storage",
        filesystem.s3_files_access_point == null ? "" : "s3_files_access_point",
        filesystem.efs_access_point == null ? "" : "efs_access_point",
      ])) == 1
    ])
    error_message = "filesystems supports at most five entries, each with exactly one storage type."
  }
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
  description = "Tool names the Harness may invoke. Defaults to no allowed tools; wildcard access must be explicitly requested with [\"*\"]."
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

variable "managed_memory" {
  description = "Optional Harness-managed Memory configuration. Cannot be combined with memory."
  type = object({
    encryption_key_arn    = optional(string)
    event_expiry_duration = optional(number)
    strategies            = optional(set(string))
  })
  default = null

  validation {
    condition = var.managed_memory == null || var.managed_memory.strategies == null || alltrue([
      for strategy in var.managed_memory.strategies : contains(["SEMANTIC", "SUMMARIZATION", "USER_PREFERENCE"], strategy)
    ])
    error_message = "managed_memory.strategies may contain SEMANTIC, SUMMARIZATION, or USER_PREFERENCE."
  }
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
    condition = var.jwt_authorizer == null || alltrue([
      for claim in var.jwt_authorizer.custom_claims : (
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
    condition = var.jwt_authorizer == null || var.jwt_authorizer.private_endpoint == null || (
      (var.jwt_authorizer.private_endpoint.managed_vpc_resource != null) !=
      (var.jwt_authorizer.private_endpoint.self_managed_lattice_resource != null)
    )
    error_message = "jwt_authorizer.private_endpoint must configure exactly one managed or self-managed VPC resource."
  }

  validation {
    condition = var.jwt_authorizer == null || alltrue([
      for override in var.jwt_authorizer.private_endpoint_overrides : (
        (override.private_endpoint.managed_vpc_resource != null) !=
        (override.private_endpoint.self_managed_lattice_resource != null)
      )
    ])
    error_message = "Each JWT private endpoint override must configure exactly one managed or self-managed VPC resource."
  }
}

variable "tools" {
  description = "Opt-in Harness tool configurations. Remote MCP headers and inline schemas are sensitive provider attributes."
  type = list(object({
    type = string
    name = optional(string)
    config = optional(object({
      remote_mcp = optional(object({
        url     = string
        headers = optional(map(string), {})
      }))
      agentcore_browser = optional(object({
        browser_arn = optional(string)
      }))
      agentcore_gateway = optional(object({
        gateway_arn = string
        outbound_auth = optional(object({
          aws_iam = optional(bool)
          none    = optional(bool)
          oauth = optional(object({
            provider_arn       = string
            scopes             = list(string)
            custom_parameters  = optional(map(string), {})
            grant_type         = optional(string)
            default_return_url = optional(string)
          }))
        }))
      }))
      inline_function = optional(object({
        description  = string
        input_schema = string
      }))
      agentcore_code_interpreter = optional(object({
        code_interpreter_arn = optional(string)
      }))
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for tool in var.tools : contains([
        "remote_mcp",
        "agentcore_browser",
        "agentcore_gateway",
        "inline_function",
        "agentcore_code_interpreter",
      ], tool.type)
    ])
    error_message = "Each tool.type must be a Managed Harness tool type supported by AgentCore."
  }

  validation {
    condition = alltrue([
      for tool in var.tools : tool.config == null || (
        length(compact([
          tool.config.remote_mcp == null ? "" : "remote_mcp",
          tool.config.agentcore_browser == null ? "" : "agentcore_browser",
          tool.config.agentcore_gateway == null ? "" : "agentcore_gateway",
          tool.config.inline_function == null ? "" : "inline_function",
          tool.config.agentcore_code_interpreter == null ? "" : "agentcore_code_interpreter",
          ])) == 1 && contains(compact([
          tool.config.remote_mcp == null ? "" : "remote_mcp",
          tool.config.agentcore_browser == null ? "" : "agentcore_browser",
          tool.config.agentcore_gateway == null ? "" : "agentcore_gateway",
          tool.config.inline_function == null ? "" : "inline_function",
          tool.config.agentcore_code_interpreter == null ? "" : "agentcore_code_interpreter",
        ]), tool.type)
      )
    ])
    error_message = "When tool.config is set, it must contain exactly the configuration matching tool.type."
  }

  validation {
    condition = alltrue([
      for tool in var.tools : try(tool.config.agentcore_gateway.outbound_auth, null) == null || length(compact([
        coalesce(try(tool.config.agentcore_gateway.outbound_auth.aws_iam, null), false) ? "aws_iam" : "",
        coalesce(try(tool.config.agentcore_gateway.outbound_auth.none, null), false) ? "none" : "",
        try(tool.config.agentcore_gateway.outbound_auth.oauth, null) == null ? "" : "oauth",
      ])) == 1
    ])
    error_message = "AgentCore Gateway outbound_auth must enable exactly one of aws_iam, none, or oauth."
  }
}

variable "truncation" {
  description = "Optional conversation truncation strategy and provider-native configuration."
  type = object({
    strategy = string
    config = optional(object({
      sliding_window = optional(object({
        messages_count = optional(number)
      }))
      summarization = optional(object({
        summary_ratio               = optional(number)
        preserve_recent_messages    = optional(number)
        summarization_system_prompt = optional(string)
      }))
    }))
  })
  default = null

  validation {
    condition     = var.truncation == null || contains(["sliding_window", "summarization", "none"], var.truncation.strategy)
    error_message = "truncation.strategy must be sliding_window, summarization, or none."
  }

  validation {
    condition = var.truncation == null || var.truncation.config == null || length(compact([
      var.truncation.config.sliding_window == null ? "" : "sliding_window",
      var.truncation.config.summarization == null ? "" : "summarization",
    ])) <= 1
    error_message = "truncation.config may configure at most one strategy-specific block."
  }
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
