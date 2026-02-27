# ==============================================================================
# Data Sources
# ==============================================================================

data "aws_caller_identity" "current" {}

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
  role_arn = var.create_role ? aws_iam_role.gateway[0].arn : var.role_arn
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
}
