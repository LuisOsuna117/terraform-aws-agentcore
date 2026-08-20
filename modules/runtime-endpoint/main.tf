resource "aws_bedrockagentcore_agent_runtime_endpoint" "this" {
  agent_runtime_id      = var.agent_runtime_id
  agent_runtime_version = var.agent_runtime_version
  name                  = var.name
  description           = var.description
  tags = merge(
    {
      Module    = "terraform-aws-agentcore"
      ManagedBy = "Terraform"
    },
    var.tags,
  )
}
