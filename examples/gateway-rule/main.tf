provider "aws" {
  region = var.aws_region
}

module "gateway_rule" {
  source = "../../modules/gateway-rule"

  gateway_identifier = var.gateway_identifier
  priority           = 100
  conditions = [{
    match_paths = {
      any_of = ["/operator/*"]
    }
  }]
  static_target_name = var.target_name
}
