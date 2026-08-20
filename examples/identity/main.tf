provider "aws" {
  region = var.region
}

module "agentcore" {
  source = "../.."

  name = var.name

  workload_identities = {
    application = {
      allowed_oauth_return_urls = [var.oauth_return_url]
    }
  }

  oauth2_credential_providers = {
    external_api = {
      client_id_write_only     = var.oauth_client_id
      client_secret_write_only = var.oauth_client_secret
      credentials_version      = var.credentials_version
      discovery_url            = var.oauth_discovery_url
    }
  }

  tags = {
    Environment = "example"
    Terraform   = "true"
  }
}
