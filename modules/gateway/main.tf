data "aws_caller_identity" "current" {}

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
      }
    }]
  })

  tags = var.tags
}

locals {
  role_arn  = var.create_role ? aws_iam_role.gateway[0].arn : var.role_arn
  role_name = var.create_role ? aws_iam_role.gateway[0].name : (var.role_arn != null ? element(reverse(split("/", var.role_arn)), 0) : null)

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
}

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = var.create_role || var.role_arn != null
      error_message = "role_arn must be provided when create_role = false."
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
      }
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

  depends_on = [terraform_data.validations]
}

resource "aws_iam_role_policy" "gateway_invoke_agent_runtime" {
  count = length(local.runtime_invoke_resources) > 0 ? 1 : 0

  name = "${var.name}-invoke-agent-runtime"
  role = local.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "InvokeAgentCoreRuntimeTargets"
      Effect   = "Allow"
      Action   = ["bedrock-agentcore:InvokeAgentRuntime"]
      Resource = local.runtime_invoke_resources
    }]
  })

  depends_on = [terraform_data.validations]
}

resource "time_sleep" "gateway_invoke_policy_propagation" {
  count = length(local.runtime_invoke_resources) > 0 ? 1 : 0

  create_duration = "45s"

  depends_on = [aws_iam_role_policy.gateway_invoke_agent_runtime]
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

  depends_on = [time_sleep.gateway_invoke_policy_propagation]
}
