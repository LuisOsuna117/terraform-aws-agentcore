# ==============================================================================
# Example: Gateway with AgentCore Runtime MCP Target
#
# Provisions a standalone AgentCore MCP Gateway and attaches one Gateway Target
# backed by an AgentCore Runtime. The module derives the Runtime invoke endpoint,
# configures outbound SigV4 auth with the gateway IAM role, and grants
# bedrock-agentcore:InvokeAgentRuntime on the runtime ARN.
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
    runtime = {
      description       = "AgentCore Runtime MCP server."
      agent_runtime_arn = var.agent_runtime_arn
      qualifier         = var.qualifier
    }
  }

  tags = {
    Environment = "example"
    Workflow    = "gateway-agent-runtime-target"
  }
}
