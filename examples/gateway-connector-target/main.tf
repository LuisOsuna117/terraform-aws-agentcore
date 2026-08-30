provider "aws" {
  region = var.aws_region
}

module "web_search" {
  source = "../../modules/gateway-connector-target"

  gateway_identifier = var.gateway_identifier
  name               = "web-search"
  connector_id       = "web-search"
  connector_version  = "1.2.0"
  configurations = [{
    name = "WebSearch"
    parameter_values = {
      domainFilter = {
        include = var.allowed_domains
        exclude = var.excluded_domains
      }
    }
  }]

  tags = {
    Example = "gateway-connector-target"
  }
}
