provider "aws" {
  region = var.aws_region
}

module "gateway_target" {
  source = "../../modules/gateway-target"

  gateway_identifier = var.gateway_identifier
  name               = "operator-runtime"
  credential_mode    = "JWT_PASSTHROUGH"
  runtime_arn        = var.runtime_arn
}
