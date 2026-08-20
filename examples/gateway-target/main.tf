provider "aws" {
  region = var.aws_region
}

module "gateway_target" {
  source = "../../modules/gateway-target"

  gateway_identifier = var.gateway_identifier
  name               = "operator-runtime"

  target_configuration = {
    http = {
      agentcore_runtime = {
        arn       = var.runtime_arn
        qualifier = "DEFAULT"
      }
    }
  }

  credential_provider_configuration = {
    jwt_passthrough = true
  }
}
