terraform {
  required_version = ">= 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.21"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5"
    }
  }
}
