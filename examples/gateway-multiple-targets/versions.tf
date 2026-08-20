terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.61, < 7.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Example   = "terraform-aws-agentcore/gateway-multiple-targets"
      ManagedBy = "Terraform"
    }
  }
}
