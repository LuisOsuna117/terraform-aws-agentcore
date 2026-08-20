data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "gateway" {
  count = var.create_role ? 1 : 0

  name = "${var.name}-gateway-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AgentCoreGatewayAssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "bedrock-agentcore.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:bedrock-agentcore:${coalesce(var.region, data.aws_region.current.region)}:${data.aws_caller_identity.current.account_id}:gateway/${var.name}-*"
        }
      }
    }]
  })

  tags = var.tags
}

locals {
  role_arn  = var.create_role ? aws_iam_role.gateway[0].arn : var.role_arn
  role_name = var.create_role ? aws_iam_role.gateway[0].name : null

  effective_region    = coalesce(var.region, data.aws_region.current.region)
  gateway_arn_pattern = "arn:${data.aws_partition.current.partition}:bedrock-agentcore:${local.effective_region}:${data.aws_caller_identity.current.account_id}:gateway/${var.name}-*"

  mcp_targets = {
    for key, target in var.targets : key => target
    if try(target.target_configuration.mcp, null) != null
  }

  http_targets = {
    for key, target in var.targets : key => target
    if try(target.target_configuration.http, null) != null
  }

  effective_protocol_type = var.protocol_type != null ? var.protocol_type : (length(local.mcp_targets) > 0 ? "MCP" : null)

  raw_target_names = {
    for key, target in var.targets : key => substr(replace(coalesce(try(target.name, null), key), "/[^0-9A-Za-z-]/", "-"), 0, 93)
  }

  target_names = {
    for key, name in local.raw_target_names : key => can(regex("^[0-9A-Za-z]", name)) ? name : "target-${name}"
  }

  inferred_runtime_invoke_arns = toset([
    for target in values(local.http_targets) : target.target_configuration.http.agentcore_runtime.arn
    if try(target.credential_provider_configuration.gateway_iam_role, null) != null
  ])

  runtime_invoke_arns = setunion(var.runtime_invoke_arns, local.inferred_runtime_invoke_arns)
  runtime_invoke_resources = toset(flatten([
    for arn in local.runtime_invoke_arns : [
      arn,
      "${arn}/runtime-endpoint/*",
    ]
  ]))

  lambda_target_arns = toset(compact([
    for target in values(local.mcp_targets) : try(target.target_configuration.mcp.lambda.lambda_arn, null)
  ]))

  interceptor_lambda_arns = toset([
    for interceptor in var.interceptor_configurations : interceptor.lambda_arn
  ])

  lambda_invoke_arns = setunion(local.lambda_target_arns, local.interceptor_lambda_arns)

  api_gateway_invoke_arns = toset(compact([
    for target in values(local.mcp_targets) : try(
      "arn:${data.aws_partition.current.partition}:execute-api:${local.effective_region}:${data.aws_caller_identity.current.account_id}:${target.target_configuration.mcp.api_gateway.rest_api_id}/${target.target_configuration.mcp.api_gateway.stage}/*/*",
      null,
    )
  ]))

  s3_schema_uris = toset(compact(flatten([
    for target in values(local.mcp_targets) : [
      try(target.target_configuration.mcp.lambda.tool_schema.s3.uri, null),
      try(target.target_configuration.mcp.mcp_server.mcp_tool_schema.s3.uri, null),
      try(target.target_configuration.mcp.open_api_schema.s3.uri, null),
      try(target.target_configuration.mcp.smithy_model.s3.uri, null),
    ]
  ])))

  s3_schema_arns = toset([
    for uri in local.s3_schema_uris : "arn:${data.aws_partition.current.partition}:s3:::${trimprefix(uri, "s3://")}"
  ])

  inferred_role_policy_statements = concat(
    length(local.runtime_invoke_resources) == 0 ? [] : [{
      sid       = "InvokeAgentCoreRuntimeTargets"
      effect    = "Allow"
      actions   = toset(["bedrock-agentcore:InvokeAgentRuntime"])
      resources = local.runtime_invoke_resources
      condition = null
    }],
    length(local.lambda_invoke_arns) == 0 ? [] : [{
      sid       = "InvokeLambdaTargets"
      effect    = "Allow"
      actions   = toset(["lambda:InvokeFunction"])
      resources = local.lambda_invoke_arns
      condition = null
    }],
    length(local.api_gateway_invoke_arns) == 0 ? [] : [{
      sid       = "InvokeApiGatewayTargets"
      effect    = "Allow"
      actions   = toset(["execute-api:Invoke"])
      resources = local.api_gateway_invoke_arns
      condition = null
    }],
    length(local.s3_schema_arns) == 0 ? [] : [{
      sid       = "ReadGatewayToolSchemas"
      effect    = "Allow"
      actions   = toset(["s3:GetObject"])
      resources = local.s3_schema_arns
      condition = null
    }],
    var.policy_engine_configuration == null ? [] : [{
      sid     = "UseAgentCorePolicyEngine"
      effect  = "Allow"
      actions = toset(["bedrock-agentcore:AuthorizeAction", "bedrock-agentcore:PartiallyAuthorizeActions", "bedrock-agentcore:GetPolicyEngine"])
      resources = toset([
        var.policy_engine_configuration.arn,
        local.gateway_arn_pattern,
      ])
      condition = null
    }],
  )

  effective_role_policy_statements = concat(local.inferred_role_policy_statements, var.role_policy_statements)
}

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = var.create_role || var.role_arn != null
      error_message = "role_arn must be provided when create_role = false."
    }

    precondition {
      condition     = (var.authorizer_type == "CUSTOM_JWT") == (var.authorizer_configuration != null)
      error_message = "authorizer_configuration must be set only when authorizer_type is CUSTOM_JWT."
    }

    precondition {
      condition     = length(distinct(values(local.target_names))) == length(local.target_names)
      error_message = "Each Gateway Target must resolve to a unique name."
    }

    precondition {
      condition     = !(length(local.mcp_targets) > 0 && length(local.http_targets) > 0)
      error_message = "A Gateway cannot mix MCP aggregation targets and direct HTTP targets. Use separate Gateways."
    }

    precondition {
      condition     = length(local.http_targets) == 0 || local.effective_protocol_type == null
      error_message = "Direct HTTP targets require protocol_type = null."
    }

    precondition {
      condition     = length(local.mcp_targets) == 0 || local.effective_protocol_type == "MCP"
      error_message = "MCP targets require protocol_type = \"MCP\"; it is inferred when protocol_type is null."
    }

    precondition {
      condition     = var.protocol_configuration == null || local.effective_protocol_type == "MCP"
      error_message = "protocol_configuration is only valid for an MCP Gateway."
    }
  }
}

resource "aws_bedrockagentcore_gateway" "this" {
  name     = var.name
  role_arn = local.role_arn
  region   = var.region

  description     = var.description
  authorizer_type = var.authorizer_type
  protocol_type   = local.effective_protocol_type
  exception_level = var.exception_level
  kms_key_arn     = var.kms_key_arn

  dynamic "authorizer_configuration" {
    for_each = var.authorizer_type == "CUSTOM_JWT" && var.authorizer_configuration != null ? [var.authorizer_configuration] : []
    content {
      custom_jwt_authorizer {
        discovery_url    = authorizer_configuration.value.discovery_url
        allowed_audience = authorizer_configuration.value.allowed_audience
        allowed_clients  = authorizer_configuration.value.allowed_clients
        allowed_scopes   = authorizer_configuration.value.allowed_scopes

        dynamic "allowed_workload_configuration" {
          for_each = length(authorizer_configuration.value.workload_identities) + length(authorizer_configuration.value.hosting_environment_arns) == 0 ? [] : [1]
          content {
            workload_identities = authorizer_configuration.value.workload_identities

            dynamic "hosting_environment" {
              for_each = authorizer_configuration.value.hosting_environment_arns
              content {
                arn = hosting_environment.value
              }
            }
          }
        }

        dynamic "custom_claim" {
          for_each = authorizer_configuration.value.custom_claims
          content {
            inbound_token_claim_name       = custom_claim.value.inbound_token_claim_name
            inbound_token_claim_value_type = custom_claim.value.inbound_token_claim_value_type

            authorizing_claim_match_value {
              claim_match_operator = custom_claim.value.claim_match_operator

              claim_match_value {
                match_value_string      = custom_claim.value.match_value_string
                match_value_string_list = custom_claim.value.match_value_string_list
              }
            }
          }
        }

        dynamic "private_endpoint" {
          for_each = authorizer_configuration.value.private_endpoint == null ? [] : [authorizer_configuration.value.private_endpoint]
          content {
            dynamic "managed_vpc_resource" {
              for_each = private_endpoint.value.managed_vpc_resource == null ? [] : [private_endpoint.value.managed_vpc_resource]
              content {
                endpoint_ip_address_type = managed_vpc_resource.value.endpoint_ip_address_type
                subnet_ids               = managed_vpc_resource.value.subnet_ids
                vpc_identifier           = managed_vpc_resource.value.vpc_identifier
                routing_domain           = managed_vpc_resource.value.routing_domain
                security_group_ids       = managed_vpc_resource.value.security_group_ids
                tags                     = managed_vpc_resource.value.tags
              }
            }

            dynamic "self_managed_lattice_resource" {
              for_each = private_endpoint.value.self_managed_lattice_resource == null ? [] : [private_endpoint.value.self_managed_lattice_resource]
              content {
                resource_configuration_identifier = self_managed_lattice_resource.value.resource_configuration_identifier
              }
            }
          }
        }

        dynamic "private_endpoint_overrides" {
          for_each = authorizer_configuration.value.private_endpoint_overrides
          content {
            domain = private_endpoint_overrides.value.domain

            private_endpoint {
              dynamic "managed_vpc_resource" {
                for_each = private_endpoint_overrides.value.private_endpoint.managed_vpc_resource == null ? [] : [private_endpoint_overrides.value.private_endpoint.managed_vpc_resource]
                content {
                  endpoint_ip_address_type = managed_vpc_resource.value.endpoint_ip_address_type
                  subnet_ids               = managed_vpc_resource.value.subnet_ids
                  vpc_identifier           = managed_vpc_resource.value.vpc_identifier
                  routing_domain           = managed_vpc_resource.value.routing_domain
                  security_group_ids       = managed_vpc_resource.value.security_group_ids
                  tags                     = managed_vpc_resource.value.tags
                }
              }

              dynamic "self_managed_lattice_resource" {
                for_each = private_endpoint_overrides.value.private_endpoint.self_managed_lattice_resource == null ? [] : [private_endpoint_overrides.value.private_endpoint.self_managed_lattice_resource]
                content {
                  resource_configuration_identifier = self_managed_lattice_resource.value.resource_configuration_identifier
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "protocol_configuration" {
    for_each = var.protocol_configuration == null ? [] : [var.protocol_configuration]
    content {
      mcp {
        instructions       = protocol_configuration.value.instructions
        search_type        = protocol_configuration.value.search_type
        supported_versions = protocol_configuration.value.supported_versions

        dynamic "session_configuration" {
          for_each = protocol_configuration.value.session_timeout_in_seconds == null ? [] : [protocol_configuration.value.session_timeout_in_seconds]
          content {
            session_timeout_in_seconds = session_configuration.value
          }
        }

        dynamic "streaming_configuration" {
          for_each = protocol_configuration.value.enable_response_streaming == null ? [] : [protocol_configuration.value.enable_response_streaming]
          content {
            enable_response_streaming = streaming_configuration.value
          }
        }
      }
    }
  }

  dynamic "policy_engine_configuration" {
    for_each = var.policy_engine_configuration == null ? [] : [var.policy_engine_configuration]
    content {
      arn  = policy_engine_configuration.value.arn
      mode = policy_engine_configuration.value.mode
    }
  }

  dynamic "interceptor_configuration" {
    for_each = var.interceptor_configurations
    content {
      interception_points = interceptor_configuration.value.interception_points

      interceptor {
        lambda {
          arn = interceptor_configuration.value.lambda_arn
        }
      }

      dynamic "input_configuration" {
        for_each = interceptor_configuration.value.pass_request_headers ? [1] : []
        content {
          pass_request_headers = true
        }
      }
    }
  }

  tags = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    terraform_data.validations,
    time_sleep.gateway_role_policy_propagation,
  ]
}

resource "aws_iam_role_policy" "gateway_permissions" {
  count = var.create_role && length(local.effective_role_policy_statements) > 0 ? 1 : 0

  name = "${var.name}-gateway-permissions"
  role = local.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for statement in local.effective_role_policy_statements : merge(
        {
          Effect   = statement.effect
          Action   = statement.actions
          Resource = statement.resources
        },
        statement.sid == null ? {} : { Sid = statement.sid },
        statement.condition == null ? {} : { Condition = statement.condition },
      )
    ]
  })

  depends_on = [terraform_data.validations]
}

resource "aws_iam_role_policy_attachment" "gateway" {
  for_each = var.create_role ? var.role_policy_arns : []

  role       = local.role_name
  policy_arn = each.value
}

resource "time_sleep" "gateway_role_policy_propagation" {
  count = var.create_role && (length(local.effective_role_policy_statements) > 0 || length(var.role_policy_arns) > 0) ? 1 : 0

  create_duration = "45s"

  depends_on = [
    aws_iam_role_policy.gateway_permissions,
    aws_iam_role_policy_attachment.gateway,
  ]
}

module "target" {
  source   = "../gateway-target"
  for_each = var.targets

  gateway_identifier                = aws_bedrockagentcore_gateway.this.gateway_id
  name                              = local.target_names[each.key]
  description                       = try(each.value.description, null)
  region                            = try(each.value.region, null)
  target_configuration              = each.value.target_configuration
  credential_provider_configuration = try(each.value.credential_provider_configuration, null)
  metadata_configuration            = try(each.value.metadata_configuration, null)
  private_endpoint                  = try(each.value.private_endpoint, null)
  timeouts                          = try(each.value.timeouts, null)

  depends_on = [time_sleep.gateway_role_policy_propagation]
}
