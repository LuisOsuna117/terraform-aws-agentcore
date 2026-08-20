provider "aws" {
  region = var.region
}

module "agentcore" {
  source = "../.."

  name = var.name

  browsers = {
    readonly = {}
  }

  browser_profiles = {
    readonly = {}
  }

  tags = {
    Environment = "example"
    Terraform   = "true"
  }
}
