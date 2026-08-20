provider "aws" {
  region = var.region
}

module "agentcore" {
  source = "../.."

  name = var.name

  image_builds = {
    agent = {
      source_dir             = "${path.module}/agent-code"
      trigger_build_on_apply = var.trigger_build_on_apply
    }
  }

  tags = {
    Environment = "example"
    Terraform   = "true"
  }
}
