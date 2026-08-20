provider "aws" {
  region = var.aws_region
}

module "browser" {
  source = "../../modules/browser"

  name        = var.name
  description = "Managed browser for read-only research workflows"

  profiles = {
    research = {
      description = "Research session profile"
    }
  }

  tags = var.tags
}
