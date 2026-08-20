provider "aws" {
  region = var.region
}

module "agentcore" {
  source = "../.."

  name = var.name

  runtimes = {
    primary = {
      role_arn       = var.runtime_role_arn
      image_uri      = var.image_uri
      authentication = "AWS_IAM"
    }
  }

  tags = {
    Environment = "example"
    Terraform   = "true"
  }
}
