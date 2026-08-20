provider "aws" {
  region = var.aws_region
}

module "policy" {
  source = "../../modules/policy"

  name        = var.name
  description = "AgentCore authorization policies"

  policies = {
    invoke = {
      cedar_statement = var.cedar_statement
    }
  }

  tags = var.tags
}
