terraform {
  required_version = ">= 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.48"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Example   = "terraform-aws-agentcore/gateway-agent-runtime-target"
      ManagedBy = "Terraform"
    }
  }
}
