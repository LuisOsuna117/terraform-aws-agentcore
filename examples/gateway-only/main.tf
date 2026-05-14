# ==============================================================================
# Example: AgentCore Gateway Only
#
# Provisions a standalone AgentCore MCP Gateway with AWS IAM inbound auth and
# no targets. Add targets later by setting gateway_mcp_targets.
#
# Run:
#   tofu init
#   tofu apply
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

  tags = {
    Environment = "example"
    Workflow    = "gateway-only"
  }
}
