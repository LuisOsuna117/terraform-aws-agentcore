mock_provider "aws" {}

run "identity_is_opt_in_and_uses_write_only_credentials" {
  command = plan

  module {
    source = "./modules/identity"
  }

  variables {
    name = "community-agent"

    workload_identities = {
      runtime = {
        allowed_oauth_return_urls = ["https://app.example.com/callback"]
      }
    }

    api_key_credential_providers = {
      service = {
        secret_version = 1
      }
    }
    api_key_values = {
      service = "test-api-key"
    }

    oauth2_credential_providers = {
      oidc = {
        vendor              = "CustomOauth2"
        credentials_version = 1
        discovery_url       = "https://id.example.com/.well-known/openid-configuration"
      }
    }
    oauth2_client_ids = {
      oidc = "test-client-id"
    }
    oauth2_client_secrets = {
      oidc = "test-client-secret"
    }

    token_vault_cmk = {
      key_type = "ServiceManagedKey"
    }
  }

  assert {
    condition     = length(output.workload_identity_arns) == 1
    error_message = "The identity module must create each requested workload identity."
  }

  assert {
    condition     = aws_bedrockagentcore_api_key_credential_provider.this["service"].api_key_wo_version == 1
    error_message = "API key providers must use versioned write-only credentials."
  }

  assert {
    condition     = aws_bedrockagentcore_oauth2_credential_provider.this["oidc"].credential_provider_vendor == "CustomOauth2"
    error_message = "OAuth2 providers must preserve the selected provider vendor."
  }
}
