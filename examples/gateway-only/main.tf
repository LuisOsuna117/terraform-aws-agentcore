# ==============================================================================
# Example: AgentCore Gateway Only
#
# Provisions a standalone general AgentCore Gateway with AWS IAM inbound auth
# and no targets. Add targets later with gateway_targets. Set
# gateway_protocol_type = "MCP" when the empty gateway is intended for MCP
# aggregation targets.
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
