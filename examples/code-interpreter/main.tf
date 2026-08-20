provider "aws" {
  region = var.region
}

module "agentcore" {
  source = "../.."

  name = var.name

  code_interpreters = {
    isolated = {}
  }

  tags = {
    Environment = "example"
    Terraform   = "true"
  }
}
