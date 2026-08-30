variable "gateway_identifier" {
  description = "ID of the AgentCore Gateway that owns this target."
  type        = string
}

variable "name" {
  description = "Gateway Target name."
  type        = string
}

variable "description" {
  description = "Gateway Target description."
  type        = string
  default     = null
}

variable "region" {
  description = "AWS Region in which to manage the Gateway Target. Defaults to the provider Region."
  type        = string
  default     = null
}

variable "target_configuration" {
  description = "Target configuration. Set exactly one of http or mcp."
  type = object({
    http = optional(object({
      agentcore_runtime = object({
        arn       = string
        qualifier = optional(string)
      })
    }))
    mcp = optional(object({
      api_gateway = optional(object({
        rest_api_id = string
        stage       = string
        api_gateway_tool_configuration = object({
          tool_filter = optional(set(object({
            filter_path = string
            methods     = set(string)
          })), [])
          tool_override = optional(set(object({
            path        = string
            method      = string
            name        = string
            description = optional(string)
          })), [])
        })
      }))
      lambda = optional(object({
        lambda_arn = string
        tool_schema = object({
          inline_payload = optional(object({
            name          = string
            description   = string
            input_schema  = any
            output_schema = optional(any)
          }))
          s3 = optional(object({
            uri                     = optional(string)
            bucket_owner_account_id = optional(string)
          }))
        })
      }))
      mcp_server = optional(object({
        endpoint          = string
        listing_mode      = optional(string)
        resource_priority = optional(number)
        mcp_tool_schema = optional(object({
          inline_payload = optional(object({
            payload = string
          }))
          s3 = optional(object({
            uri                     = string
            bucket_owner_account_id = optional(string)
          }))
        }))
      }))
      open_api_schema = optional(object({
        inline_payload = optional(object({
          payload = string
        }))
        s3 = optional(object({
          uri                     = optional(string)
          bucket_owner_account_id = optional(string)
        }))
      }))
      smithy_model = optional(object({
        inline_payload = optional(object({
          payload = string
        }))
        s3 = optional(object({
          uri                     = optional(string)
          bucket_owner_account_id = optional(string)
        }))
      }))
    }))
  })

  validation {
    condition = length(compact([
      var.target_configuration.http == null ? "" : "http",
      var.target_configuration.mcp == null ? "" : "mcp",
    ])) == 1
    error_message = "target_configuration must set exactly one of http or mcp."
  }

  validation {
    condition = var.target_configuration.mcp == null || length(compact([
      try(var.target_configuration.mcp.api_gateway, null) == null ? "" : "api_gateway",
      try(var.target_configuration.mcp.lambda, null) == null ? "" : "lambda",
      try(var.target_configuration.mcp.mcp_server, null) == null ? "" : "mcp_server",
      try(var.target_configuration.mcp.open_api_schema, null) == null ? "" : "open_api_schema",
      try(var.target_configuration.mcp.smithy_model, null) == null ? "" : "smithy_model",
    ])) == 1
    error_message = "target_configuration.mcp must set exactly one target: api_gateway, lambda, mcp_server, open_api_schema, or smithy_model."
  }

  validation {
    condition = try(var.target_configuration.mcp.lambda, null) == null || length(compact([
      try(var.target_configuration.mcp.lambda.tool_schema.inline_payload, null) == null ? "" : "inline_payload",
      try(var.target_configuration.mcp.lambda.tool_schema.s3, null) == null ? "" : "s3",
    ])) == 1
    error_message = "A Lambda tool_schema must set exactly one of inline_payload or s3."
  }

  validation {
    condition = try(var.target_configuration.mcp.mcp_server.mcp_tool_schema, null) == null || length(compact([
      try(var.target_configuration.mcp.mcp_server.mcp_tool_schema.inline_payload, null) == null ? "" : "inline_payload",
      try(var.target_configuration.mcp.mcp_server.mcp_tool_schema.s3, null) == null ? "" : "s3",
    ])) == 1
    error_message = "An MCP Server mcp_tool_schema must set exactly one of inline_payload or s3."
  }

  validation {
    condition = try(var.target_configuration.mcp.open_api_schema, null) == null || length(compact([
      try(var.target_configuration.mcp.open_api_schema.inline_payload, null) == null ? "" : "inline_payload",
      try(var.target_configuration.mcp.open_api_schema.s3, null) == null ? "" : "s3",
    ])) == 1
    error_message = "An OpenAPI target must set exactly one of inline_payload or s3."
  }

  validation {
    condition = try(var.target_configuration.mcp.smithy_model, null) == null || length(compact([
      try(var.target_configuration.mcp.smithy_model.inline_payload, null) == null ? "" : "inline_payload",
      try(var.target_configuration.mcp.smithy_model.s3, null) == null ? "" : "s3",
    ])) == 1
    error_message = "A Smithy target must set exactly one of inline_payload or s3."
  }
}

variable "credential_provider_configuration" {
  description = "Optional outbound credential configuration. Omit for targets that explicitly support anonymous access."
  type = object({
    api_key = optional(object({
      provider_arn              = string
      credential_location       = optional(string)
      credential_parameter_name = optional(string)
      credential_prefix         = optional(string)
    }))
    caller_iam_credentials = optional(object({
      service = string
      region  = optional(string)
    }))
    gateway_iam_role = optional(object({
      service = optional(string)
      region  = optional(string)
    }))
    jwt_passthrough = optional(bool, false)
    oauth = optional(object({
      provider_arn       = string
      grant_type         = optional(string)
      scopes             = set(string)
      default_return_url = optional(string)
      custom_parameters  = optional(map(string), {})
    }))
  })
  default = null

  validation {
    condition = var.credential_provider_configuration == null || length(compact([
      try(var.credential_provider_configuration.api_key, null) == null ? "" : "api_key",
      try(var.credential_provider_configuration.caller_iam_credentials, null) == null ? "" : "caller_iam_credentials",
      try(var.credential_provider_configuration.gateway_iam_role, null) == null ? "" : "gateway_iam_role",
      try(var.credential_provider_configuration.jwt_passthrough, false) ? "jwt_passthrough" : "",
      try(var.credential_provider_configuration.oauth, null) == null ? "" : "oauth",
    ])) == 1
    error_message = "credential_provider_configuration must set exactly one credential provider."
  }
}

variable "metadata_configuration" {
  description = "Optional HTTP header and query parameter propagation configuration."
  type = object({
    allowed_query_parameters = optional(set(string), [])
    allowed_request_headers  = optional(set(string), [])
    allowed_response_headers = optional(set(string), [])
  })
  default = null

  validation {
    condition = var.metadata_configuration == null ? true : alltrue([
      length(var.metadata_configuration.allowed_query_parameters) <= 10,
      length(var.metadata_configuration.allowed_request_headers) <= 10,
      length(var.metadata_configuration.allowed_response_headers) <= 10,
    ])
    error_message = "Each metadata propagation set supports at most 10 values."
  }
}

variable "private_endpoint" {
  description = "Optional private connectivity through an AWS-managed VPC resource or an existing VPC Lattice resource configuration."
  type = object({
    managed_vpc_resource = optional(object({
      vpc_identifier           = string
      subnet_ids               = set(string)
      endpoint_ip_address_type = string
      security_group_ids       = optional(set(string), [])
      routing_domain           = optional(string)
      tags                     = optional(map(string), {})
    }))
    self_managed_lattice_resource = optional(object({
      resource_configuration_identifier = string
    }))
  })
  default = null

  validation {
    condition = var.private_endpoint == null || length(compact([
      try(var.private_endpoint.managed_vpc_resource, null) == null ? "" : "managed_vpc_resource",
      try(var.private_endpoint.self_managed_lattice_resource, null) == null ? "" : "self_managed_lattice_resource",
    ])) == 1
    error_message = "private_endpoint must set exactly one of managed_vpc_resource or self_managed_lattice_resource."
  }
}

variable "timeouts" {
  description = "Optional create, update, and delete timeout overrides."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
