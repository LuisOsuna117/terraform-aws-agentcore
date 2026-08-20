resource "aws_bedrockagentcore_agent_runtime" "this" {
  for_each = local.create ? var.runtimes : {}

  agent_runtime_name = coalesce(each.value.name, replace("${var.name}_${each.key}", "-", "_"))
  description        = each.value.description
  role_arn           = each.value.role_arn
  environment_variables = merge(
    each.value.environment_variables,
    { for env_name, key in each.value.gateway_url_environment : env_name => aws_bedrockagentcore_gateway.this[key].gateway_url },
    { for env_name, key in each.value.memory_id_environment : env_name => aws_bedrockagentcore_memory.this[key].id },
    { for env_name, key in each.value.browser_id_environment : env_name => aws_bedrockagentcore_browser.this[key].browser_id },
    { for env_name, key in each.value.browser_profile_id_environment : env_name => aws_bedrockagentcore_browser_profile.this[key].profile_id },
    { for env_name, key in each.value.code_interpreter_id_environment : env_name => aws_bedrockagentcore_code_interpreter.this[key].code_interpreter_id },
  )
  lifecycle_configuration = [{
    idle_runtime_session_timeout = each.value.idle_timeout_seconds
    max_lifetime                 = each.value.max_lifetime_seconds
  }]
  tags = local.common_tags

  agent_runtime_artifact {
    container_configuration {
      container_uri = each.value.image_uri
    }
  }

  dynamic "authorizer_configuration" {
    for_each = each.value.authentication == "CUSTOM_JWT" ? [each.value.jwt] : []
    content {
      custom_jwt_authorizer {
        discovery_url    = authorizer_configuration.value.discovery_url
        allowed_audience = authorizer_configuration.value.allowed_audience
        allowed_clients  = authorizer_configuration.value.allowed_clients
        allowed_scopes   = authorizer_configuration.value.allowed_scopes

        dynamic "allowed_workload_configuration" {
          for_each = authorizer_configuration.value.allowed_gateway_arn != null || authorizer_configuration.value.allowed_gateway_key != null || length(authorizer_configuration.value.allowed_workload_identities) > 0 ? [1] : []
          content {
            workload_identities = length(authorizer_configuration.value.allowed_workload_identities) == 0 ? null : authorizer_configuration.value.allowed_workload_identities
            dynamic "hosting_environment" {
              for_each = authorizer_configuration.value.allowed_gateway_arn != null ? [authorizer_configuration.value.allowed_gateway_arn] : (
                authorizer_configuration.value.allowed_gateway_key == null ? [] : [aws_bedrockagentcore_gateway.this[authorizer_configuration.value.allowed_gateway_key].gateway_arn]
              )
              content {
                arn = hosting_environment.value
              }
            }
          }
        }

        dynamic "custom_claim" {
          for_each = authorizer_configuration.value.claims
          content {
            inbound_token_claim_name       = custom_claim.value.name
            inbound_token_claim_value_type = custom_claim.value.value_type
            authorizing_claim_match_value {
              claim_match_operator = custom_claim.value.operator
              claim_match_value {
                match_value_string      = custom_claim.value.string_value
                match_value_string_list = custom_claim.value.string_list
              }
            }
          }
        }
      }
    }
  }

  network_configuration {
    network_mode = each.value.network_mode
    dynamic "network_mode_config" {
      for_each = each.value.network_mode == "VPC" ? [1] : []
      content {
        security_groups = each.value.security_groups
        subnets         = each.value.subnets
      }
    }
  }

  protocol_configuration {
    server_protocol = each.value.server_protocol
  }

  dynamic "request_header_configuration" {
    for_each = length(each.value.request_headers) == 0 ? [] : [1]
    content {
      request_header_allowlist = each.value.request_headers
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.authentication != "CUSTOM_JWT" || !contains(each.value.request_headers, "Authorization")
      error_message = "Authorization is propagated by CUSTOM_JWT and must not be placed in request_headers."
    }
  }
}

resource "aws_bedrockagentcore_agent_runtime_endpoint" "this" {
  for_each = local.create ? var.runtime_endpoints : {}

  agent_runtime_id      = aws_bedrockagentcore_agent_runtime.this[each.value.runtime_key].agent_runtime_id
  agent_runtime_version = each.value.runtime_version
  name                  = coalesce(each.value.name, "${var.name}-${each.key}")
  description           = each.value.description
  tags                  = local.common_tags
}

locals {
  resource_policy_arns = local.create ? {
    for key, binding in var.resource_policies : key => binding.resource_arn != null ? binding.resource_arn : (
      binding.resource_type == "RUNTIME" ? aws_bedrockagentcore_agent_runtime.this[binding.resource_key].agent_runtime_arn :
      binding.resource_type == "GATEWAY" ? aws_bedrockagentcore_gateway.this[binding.resource_key].gateway_arn :
      aws_bedrockagentcore_memory.this[binding.resource_key].arn
    )
  } : {}
}

resource "aws_bedrockagentcore_resource_policy" "this" {
  for_each = local.create ? var.resource_policies : {}

  resource_arn = local.resource_policy_arns[each.key]
  policy = each.value.policy != null ? each.value.policy : jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "LeastPrivilegeAgentCoreAccess"
      Effect    = "Allow"
      Principal = { AWS = sort(tolist(each.value.principals)) }
      Action    = sort(tolist(each.value.actions))
      Resource  = local.resource_policy_arns[each.key]
    }]
  })
}
