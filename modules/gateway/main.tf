# ==============================================================================
# Data Sources
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# IAM — Gateway Role (optional)
# ==============================================================================

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

  agent_runtime_targets = {
    for key, target in var.mcp_targets : key => target
    if try(trimspace(target.agent_runtime_arn), "") != ""
  }

  runtime_arn_parts = {
    for key, target in local.agent_runtime_targets : key => split(":", target.agent_runtime_arn)
  }

  runtime_resource_parts = {
    for key, parts in local.runtime_arn_parts : key => split("/", join(":", slice(parts, 5, length(parts))))
  }

  runtime_resource_ids = {
    for key, parts in local.runtime_resource_parts : key => element(parts, 1)
  }

  runtime_ids = {
    for key, runtime_resource_id in local.runtime_resource_ids : key => element(split(":", runtime_resource_id), 0)
  }

  runtime_account_ids = {
    for key, parts in local.runtime_arn_parts : key => parts[4]
  }

  mcp_target_endpoints = merge(
    {
      for key, target in var.mcp_targets : key => trimspace(target.endpoint)
      if try(trimspace(target.endpoint), "") != ""
    },
    {
      for key, target in local.agent_runtime_targets : key => format(
        "https://bedrock-agentcore.%s.%s/runtimes/%s/invocations?qualifier=%s&accountId=%s",
        data.aws_region.current.id,
        data.aws_partition.current.dns_suffix,
        urlencode(local.runtime_ids[key]),
        urlencode(coalesce(target.qualifier, "DEFAULT")),
        local.runtime_account_ids[key],
      )
    },
  )

  raw_mcp_target_names = {
    for key, target in var.mcp_targets : key => substr(replace(coalesce(target.name, key), "/[^0-9A-Za-z-]/", "-"), 0, 93)
  }

  mcp_target_names = {
    for key, name in local.raw_mcp_target_names : key => can(regex("^[0-9A-Za-z]", name)) ? name : "target-${name}"
  }

  mcp_target_metadata = {
    for key, target in var.mcp_targets : key => merge(
      length(target.allowed_query_parameters) > 0 ? { AllowedQueryParameters = target.allowed_query_parameters } : {},
      length(target.allowed_request_headers) > 0 ? { AllowedRequestHeaders = target.allowed_request_headers } : {},
      length(target.allowed_response_headers) > 0 ? { AllowedResponseHeaders = target.allowed_response_headers } : {},
    )
  }

  mcp_target_stack_name_parts = {
    for key in keys(var.mcp_targets) : key => {
      name = substr(replace(var.name, "/[^0-9A-Za-z-]/", "-"), 0, 60)
      key  = substr(replace(key, "/[^0-9A-Za-z-]/", "-"), 0, 32)
      hash = substr(sha1(key), 0, 8)
    }
  }

  mcp_target_stack_names = {
    for key, parts in local.mcp_target_stack_name_parts : key => substr("agentcore-${parts.name}-${parts.key}-${parts.hash}-target", 0, 128)
  }
}

# ==============================================================================
# Cross-variable Validations
# ==============================================================================

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = var.create_role || var.role_arn != null
      error_message = "role_arn must be provided when create_role = false."
    }

    precondition {
      condition     = alltrue([for name in values(local.mcp_target_names) : can(regex("^([0-9a-zA-Z][-]?){1,100}$", name))])
      error_message = "Each MCP target name must contain only letters, numbers, and hyphens, start with a letter or number, and be at most 100 characters."
    }
  }
}

# ==============================================================================
# Gateway
# ==============================================================================

resource "aws_bedrockagentcore_gateway" "this" {
  name     = var.name
  role_arn = local.role_arn

  description     = var.description
  authorizer_type = var.authorizer_type
  protocol_type   = var.protocol_type
  exception_level = var.exception_level
  kms_key_arn     = var.kms_key_arn

  # JWT authorizer — only included when authorizer_type = "CUSTOM_JWT"
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

  # MCP protocol configuration — only included when protocol_configuration is set
  dynamic "protocol_configuration" {
    for_each = var.protocol_configuration != null ? [var.protocol_configuration] : []
    content {
      mcp {
        instructions       = protocol_configuration.value.instructions
        search_type        = protocol_configuration.value.search_type
        supported_versions = protocol_configuration.value.supported_versions
      }
    }
  }

  # Interceptors — 0 to 2 entries
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

# ==============================================================================
# Gateway Target Runtime Invoke Policy
# ==============================================================================

resource "aws_iam_role_policy" "gateway_invoke_agent_runtime" {
  count = length(local.agent_runtime_targets) > 0 ? 1 : 0

  name = "${var.name}-invoke-agent-runtime"
  role = local.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeAgentCoreRuntimeTargets"
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:InvokeAgentRuntime",
        ]
        Resource = [for target in values(local.agent_runtime_targets) : target.agent_runtime_arn]
      },
    ]
  })

  depends_on = [terraform_data.validations]
}

resource "time_sleep" "gateway_invoke_policy_propagation" {
  count = length(local.agent_runtime_targets) > 0 ? 1 : 0

  create_duration = "45s"

  depends_on = [
    aws_iam_role_policy.gateway_invoke_agent_runtime,
  ]
}

# ==============================================================================
# Gateway Targets
#
# The Terraform AWS provider currently exposes a gateway_iam_role block without
# the Service/Region SigV4 shape required by AgentCore Runtime MCP targets.
# CloudFormation supports that full shape, so target creation stays encapsulated
# here while callers use normal module inputs.
# ==============================================================================

resource "aws_cloudformation_stack" "gateway_target" {
  for_each = var.mcp_targets

  name               = local.mcp_target_stack_names[each.key]
  timeout_in_minutes = 30

  template_body = jsonencode({
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "AgentCore Gateway target managed by terraform-aws-agentcore."
    Resources = {
      GatewayTarget = {
        Type = "AWS::BedrockAgentCore::GatewayTarget"
        Properties = merge(
          {
            GatewayIdentifier = aws_bedrockagentcore_gateway.this.gateway_id
            Name              = local.mcp_target_names[each.key]
            TargetConfiguration = {
              Mcp = {
                McpServer = {
                  Endpoint = local.mcp_target_endpoints[each.key]
                }
              }
            }
          },
          try(trimspace(each.value.description), "") != "" ? { Description = trimspace(each.value.description) } : {},
          contains(keys(local.agent_runtime_targets), each.key) ? {
            CredentialProviderConfigurations = [
              {
                CredentialProviderType = "GATEWAY_IAM_ROLE"
                CredentialProvider = {
                  IamCredentialProvider = {
                    Service = "bedrock-agentcore"
                    Region  = data.aws_region.current.id
                  }
                }
              },
            ]
          } : {},
          length(local.mcp_target_metadata[each.key]) > 0 ? { MetadataConfiguration = local.mcp_target_metadata[each.key] } : {},
        )
      }
    }
    Outputs = {
      TargetId = {
        Value = {
          "Fn::GetAtt" = ["GatewayTarget", "TargetId"]
        }
      }
    }
  })

  tags = var.tags

  depends_on = [
    aws_bedrockagentcore_gateway.this,
    aws_iam_role_policy.gateway_invoke_agent_runtime,
    time_sleep.gateway_invoke_policy_propagation,
    terraform_data.validations,
  ]
}
