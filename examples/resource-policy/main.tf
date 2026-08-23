provider "aws" {
  region = var.aws_region
}

module "resource_policy" {
  source = "../../modules/policy"

  name                 = var.name
  create_policy_engine = false

  resource_policies = {
    gateway = {
      resource_arn = var.gateway_arn
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid       = "AllowTrustedCallers"
          Effect    = "Allow"
          Principal = { AWS = var.trusted_principal_arns }
          Action    = "bedrock-agentcore:InvokeGateway"
          Resource  = var.gateway_arn
        }]
      })
    }
  }
}
