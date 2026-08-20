provider "aws" {
  region = var.aws_region
}

module "runtime_endpoint" {
  source = "../../modules/runtime-endpoint"

  agent_runtime_id      = var.agent_runtime_id
  agent_runtime_version = var.agent_runtime_version
  name                  = var.endpoint_name
  tags                  = var.tags
}
