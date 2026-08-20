resource "aws_bedrockagentcore_workload_identity" "this" {
  for_each = var.workload_identities

  name                                = each.value.name
  allowed_resource_oauth2_return_urls = each.value.allowed_oauth_return_urls
}

resource "aws_bedrockagentcore_api_key_credential_provider" "this" {
  for_each = var.api_key_credential_providers

  name               = each.value.name
  api_key_wo         = each.value.api_key_write_only
  api_key_wo_version = each.value.secret_version
  tags               = local.common_tags
}

resource "aws_bedrockagentcore_oauth2_credential_provider" "this" {
  for_each = var.oauth2_credential_providers

  name                       = each.value.name
  credential_provider_vendor = "CustomOauth2"
  tags                       = local.common_tags

  oauth2_provider_config {
    custom_oauth2_provider_config {
      client_id_wo                  = each.value.client_id_write_only
      client_secret_wo              = each.value.client_secret_write_only
      client_credentials_wo_version = each.value.credentials_version

      oauth_discovery {
        discovery_url = each.value.discovery_url

        dynamic "authorization_server_metadata" {
          for_each = each.value.discovery_url == null ? [1] : []
          content {
            issuer                 = each.value.issuer
            authorization_endpoint = each.value.authorization_endpoint
            token_endpoint         = each.value.token_endpoint
            response_types         = each.value.response_types
          }
        }
      }
    }
  }
}

resource "aws_bedrockagentcore_policy_engine" "this" {
  for_each = var.policy_engines

  name               = each.value.name
  description        = each.value.description
  encryption_key_arn = each.value.encryption_key_arn
  tags               = local.common_tags
}

resource "aws_bedrockagentcore_policy" "this" {
  for_each = var.policies

  name             = each.value.name
  description      = each.value.description
  policy_engine_id = aws_bedrockagentcore_policy_engine.this[each.value.engine_key].policy_engine_id
  validation_mode  = each.value.validation_mode

  definition {
    cedar {
      statement = each.value.statement != null ? each.value.statement : format(
        "permit(principal is AgentCore::%s, action == AgentCore::Action::\"%s\", resource == AgentCore::Gateway::\"%s\")%s;",
        each.value.scoped.principal_type,
        each.value.scoped.action_id,
        aws_bedrockagentcore_gateway.this[each.value.scoped.gateway_key].gateway_arn,
        each.value.scoped.condition == null ? "" : " when { ${each.value.scoped.condition} }",
      )
    }
  }
}

resource "aws_bedrockagentcore_gateway" "this" {
  for_each = var.gateways

  name            = each.value.name
  description     = each.value.description
  role_arn        = each.value.role_arn
  authorizer_type = each.value.authentication
  kms_key_arn     = each.value.kms_key_arn
  exception_level = each.value.exception_level
  protocol_type   = each.value.protocol_type
  tags            = local.common_tags

  dynamic "authorizer_configuration" {
    for_each = each.value.authentication == "CUSTOM_JWT" ? [each.value.jwt] : []
    content {
      custom_jwt_authorizer {
        discovery_url    = authorizer_configuration.value.discovery_url
        allowed_audience = authorizer_configuration.value.allowed_audience
        allowed_clients  = authorizer_configuration.value.allowed_clients
        allowed_scopes   = authorizer_configuration.value.allowed_scopes

        dynamic "allowed_workload_configuration" {
          for_each = length(authorizer_configuration.value.allowed_workload_identities) == 0 ? [] : [1]
          content {
            workload_identities = length(authorizer_configuration.value.allowed_workload_identities) == 0 ? null : authorizer_configuration.value.allowed_workload_identities
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

  dynamic "policy_engine_configuration" {
    for_each = each.value.policy_engine_key == null ? [] : [each.value.policy_engine_key]
    content {
      arn  = aws_bedrockagentcore_policy_engine.this[policy_engine_configuration.value].policy_engine_arn
      mode = "ENFORCE"
    }
  }
}

resource "aws_bedrockagentcore_gateway_target" "this" {
  for_each = var.gateway_targets

  gateway_identifier = aws_bedrockagentcore_gateway.this[each.value.gateway_key].gateway_id
  name               = each.value.name
  description        = each.value.description

  credential_provider_configuration {
    dynamic "jwt_passthrough" {
      for_each = each.value.credential_mode == "JWT_PASSTHROUGH" ? [1] : []
      content {}
    }
    dynamic "gateway_iam_role" {
      for_each = each.value.credential_mode == "GATEWAY_IAM_ROLE" ? [1] : []
      content {
        service = each.value.signing_service
        region  = each.value.signing_region
      }
    }
    dynamic "caller_iam_credentials" {
      for_each = each.value.credential_mode == "CALLER_IAM_CREDENTIALS" ? [1] : []
      content {
        service = each.value.signing_service
        region  = each.value.signing_region
      }
    }
    dynamic "api_key" {
      for_each = each.value.credential_mode == "API_KEY" ? [1] : []
      content {
        provider_arn              = each.value.credential_provider_arn != null ? each.value.credential_provider_arn : aws_bedrockagentcore_api_key_credential_provider.this[each.value.credential_provider_key].credential_provider_arn
        credential_location       = each.value.credential_location
        credential_parameter_name = each.value.credential_parameter_name
        credential_prefix         = each.value.credential_prefix
      }
    }
    dynamic "oauth" {
      for_each = each.value.credential_mode == "OAUTH" ? [1] : []
      content {
        provider_arn       = each.value.credential_provider_arn != null ? each.value.credential_provider_arn : aws_bedrockagentcore_oauth2_credential_provider.this[each.value.credential_provider_key].credential_provider_arn
        grant_type         = each.value.oauth_grant_type
        scopes             = each.value.oauth_scopes
        default_return_url = each.value.oauth_default_return_url
        custom_parameters  = each.value.oauth_custom_parameters
      }
    }
  }

  target_configuration {
    dynamic "http" {
      for_each = each.value.target_type == "HTTP_RUNTIME" ? [1] : []
      content {
        agentcore_runtime {
          arn       = each.value.runtime_key == null ? each.value.runtime_arn : aws_bedrockagentcore_agent_runtime.this[each.value.runtime_key].agent_runtime_arn
          qualifier = each.value.qualifier
        }
      }
    }
    dynamic "mcp" {
      for_each = each.value.target_type == "MCP_SERVER" ? [1] : []
      content {
        mcp_server {
          endpoint     = each.value.mcp_endpoint
          listing_mode = each.value.mcp_listing_mode
        }
      }
    }
  }

  dynamic "metadata_configuration" {
    for_each = length(each.value.allowed_query_parameters) + length(each.value.allowed_request_headers) + length(each.value.allowed_response_headers) == 0 ? [] : [1]
    content {
      allowed_query_parameters = each.value.allowed_query_parameters
      allowed_request_headers  = each.value.allowed_request_headers
      allowed_response_headers = each.value.allowed_response_headers
    }
  }
}

resource "aws_bedrockagentcore_gateway_rule" "this" {
  for_each = var.gateway_rules

  gateway_identifier = aws_bedrockagentcore_gateway.this[each.value.gateway_key].gateway_id
  priority           = each.value.priority
  description        = each.value.description

  condition {
    match_paths {
      any_of = each.value.paths
    }
    dynamic "match_principals" {
      for_each = length(each.value.iam_principals) == 0 ? [] : [1]
      content {
        any_of {
          dynamic "iam_principal" {
            for_each = each.value.iam_principals
            content {
              arn = iam_principal.value
            }
          }
        }
      }
    }
  }

  action {
    route_to_target {
      static_route {
        target_name = each.value.target_name
      }
    }
  }
}

resource "aws_ssm_parameter" "gateway_discovery" {
  for_each = var.gateway_discovery_parameters

  name        = each.value.name
  description = each.value.description
  type        = "String"
  value       = aws_bedrockagentcore_gateway.this[each.value.gateway_key].gateway_url
  tags        = local.common_tags
}
