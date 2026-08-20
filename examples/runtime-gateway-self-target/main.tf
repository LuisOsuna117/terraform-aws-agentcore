# ==============================================================================
# Example: Runtime + Gateway + Self Runtime Target
#
# Provisions an AgentCore Runtime and AgentCore Gateway in the same module call,
# then attaches the module-created runtime as an MCP Gateway Target.
#
# Run:
#   tofu init
#   tofu apply -var="image_uri=123456789012.dkr.ecr.us-east-1.amazonaws.com/my-mcp-runtime:v1.0.0"
# ==============================================================================

module "agentcore" {
  source = "../.."
  # Uncomment once published to the registry:
  # source  = "LuisOsuna117/agentcore/aws"
  # version = "~> 0.5"

  name = var.name

  create_runtime        = true
  create_build_pipeline = false
  create_gateway        = true

  image_uri       = var.image_uri
  server_protocol = "MCP"

  gateway_authorizer_type       = "AWS_IAM"
  gateway_attach_runtime_target = true

  gateway_runtime_target = {
    name        = "runtime"
    description = "Module-created AgentCore Runtime MCP server."
    qualifier   = "DEFAULT"
  }

  tags = {
    Environment = "example"
    Workflow    = "runtime-gateway-self-target"
  }
}
