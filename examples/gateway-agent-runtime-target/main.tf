# ==============================================================================
# Example: General Gateway with AgentCore Runtime Agent Target
#
# Provisions a standalone general AgentCore Gateway (no MCP aggregation protocol)
# and attaches one direct HTTP target backed by an AgentCore Runtime. Requests are
# routed directly to /runtime/invocations without MCP protocol translation.
#
# Run:
#   tofu init
#   tofu apply -var="agent_runtime_arn=arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/MyRuntime-a1b2c3d4e5"
# ==============================================================================

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
    runtime = {
      description = "AgentCore Runtime routed directly over HTTP."
      target_configuration = {
        http = {
          agentcore_runtime = {
            arn       = var.agent_runtime_arn
            qualifier = var.qualifier
          }
        }
      }
      credential_provider_configuration = {
        gateway_iam_role = {
          service = "bedrock-agentcore"
        }
      }
    }
  }

  tags = {
    Environment = "example"
    Workflow    = "gateway-agent-runtime-target"
  }
}
