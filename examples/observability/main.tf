provider "aws" {
  region = var.region
}

module "agentcore" {
  source = "../.."

  name = var.name

  observability = {
    usage = {
      log_group_name = "/aws/bedrock-agentcore/${var.name}/usage"
    }
  }

  tags = {
    Environment = "example"
    Terraform   = "true"
  }
}
