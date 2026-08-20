# ==============================================================================
# Example: Gateway with Multiple MCP Targets
#
# Provisions a standalone AgentCore MCP Gateway with two targets:
#   - one AgentCore Runtime MCP server with derived endpoint and SigV4 auth
#   - one explicit HTTPS MCP server endpoint
#
# Run:
#   tofu init
#   tofu apply -var="agent_runtime_arn=arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/MyRuntime-a1b2c3d4e5"
# ==============================================================================

data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  runtime_arn_parts      = split(":", var.agent_runtime_arn)
  runtime_resource_parts = split("/", join(":", slice(local.runtime_arn_parts, 5, length(local.runtime_arn_parts))))
  runtime_id             = element(split(":", element(local.runtime_resource_parts, 1)), 0)
  runtime_endpoint = format(
    "https://bedrock-agentcore.%s.%s/runtimes/%s/invocations?qualifier=DEFAULT&accountId=%s",
    data.aws_region.current.region,
    data.aws_partition.current.dns_suffix,
    urlencode(local.runtime_id),
    element(local.runtime_arn_parts, 4),
  )
}

module "agentcore" {
  source = "../.."
  # Uncomment once published to the registry:
  # source  = "LuisOsuna117/agentcore/aws"
  # version = "~> 1.0"

  name = var.name

  create_runtime        = false
  create_build_pipeline = false
  create_execution_role = false
  create_gateway        = true

  gateway_authorizer_type = "AWS_IAM"

  gateway_targets = {
    datadog = {
      description = "AgentCore Runtime MCP server."
      target_configuration = {
        mcp = {
          mcp_server = {
            endpoint = local.runtime_endpoint
          }
        }
      }
      credential_provider_configuration = {
        gateway_iam_role = {
          service = "bedrock-agentcore"
        }
      }
    }

    external = {
      description = "Explicit non-AgentCore MCP server endpoint."
      target_configuration = {
        mcp = {
          mcp_server = {
            endpoint = var.external_mcp_endpoint
          }
        }
      }
      metadata_configuration = {
        allowed_request_headers  = ["x-request-id"]
        allowed_response_headers = ["x-request-id"]
      }
    }
  }

  gateway_runtime_invoke_arns = [var.agent_runtime_arn]

  tags = {
    Environment = "example"
    Workflow    = "gateway-multiple-targets"
  }
}
