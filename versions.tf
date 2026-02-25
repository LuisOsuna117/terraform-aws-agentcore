terraform {
  required_version = ">= 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.21"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

# NOTE: This module does not configure a provider block.
# AWS provider configuration (region, credentials, default_tags) is the
# responsibility of the caller. See the README for a usage example.
