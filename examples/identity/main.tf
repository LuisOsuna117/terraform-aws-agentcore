provider "aws" {
  region = var.aws_region
}

module "identity" {
  source = "../../modules/identity"

  name = var.name

  workload_identities = {
    application = {
      allowed_oauth_return_urls = var.allowed_oauth_return_urls
    }
  }

  api_key_credential_providers = {
    external_api = {
      secret_version = var.api_key_version
    }
  }
  api_key_values = {
    external_api = var.api_key
  }

  oauth2_credential_providers = {
    oidc = {
      vendor              = "CustomOauth2"
      credentials_version = var.oauth_credentials_version
      discovery_url       = var.oauth_discovery_url
    }
  }
  oauth2_client_ids = {
    oidc = var.oauth_client_id
  }
  oauth2_client_secrets = {
    oidc = var.oauth_client_secret
  }

  tags = var.tags
}
