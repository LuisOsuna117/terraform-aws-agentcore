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

module "agentcore" {
  source = "../.."
  # Uncomment once published to the registry:
  # source  = "LuisOsuna117/agentcore/aws"
  # version = "~> 0.4"

  name = var.name

  create_runtime        = false
  create_build_pipeline = false
  create_execution_role = false
  create_gateway        = true

  gateway_authorizer_type = "AWS_IAM"

  gateway_mcp_targets = {
    datadog = {
      description       = "AgentCore Runtime MCP server."
      agent_runtime_arn = var.agent_runtime_arn
      qualifier         = "DEFAULT"
    }

    external = {
      description              = "Explicit non-AgentCore MCP server endpoint."
      endpoint                 = var.external_mcp_endpoint
      allowed_request_headers  = ["x-request-id"]
      allowed_response_headers = ["x-request-id"]
    }
  }

  tags = {
    Environment = "example"
    Workflow    = "gateway-multiple-targets"
  }
}
