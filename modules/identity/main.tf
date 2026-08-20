locals {
  common_tags = merge(
    {
      Module    = "terraform-aws-agentcore"
      ManagedBy = "Terraform"
    },
    var.tags,
  )
}

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = toset(keys(var.api_key_credential_providers)) == toset(keys(var.api_key_values))
      error_message = "api_key_values must contain exactly the same keys as api_key_credential_providers."
    }

    precondition {
      condition = (
        toset(keys(var.oauth2_credential_providers)) == toset(keys(var.oauth2_client_ids)) &&
        toset(keys(var.oauth2_credential_providers)) == toset(keys(var.oauth2_client_secrets))
      )
      error_message = "oauth2_client_ids and oauth2_client_secrets must contain exactly the same keys as oauth2_credential_providers."
    }
  }
}

resource "aws_bedrockagentcore_workload_identity" "this" {
  for_each = var.workload_identities

  name                                = coalesce(each.value.name, "${var.name}-${each.key}")
  allowed_resource_oauth2_return_urls = each.value.allowed_oauth_return_urls
}

resource "aws_bedrockagentcore_api_key_credential_provider" "this" {
  for_each = var.api_key_credential_providers

  name               = coalesce(each.value.name, "${var.name}-${each.key}")
  api_key_wo         = lookup(var.api_key_values, each.key, null)
  api_key_wo_version = each.value.secret_version
  tags               = local.common_tags

  depends_on = [terraform_data.validations]
}

resource "aws_bedrockagentcore_oauth2_credential_provider" "this" {
  for_each = var.oauth2_credential_providers

  name                       = coalesce(each.value.name, "${var.name}-${each.key}")
  credential_provider_vendor = each.value.vendor
  tags                       = local.common_tags

  oauth2_provider_config {
    dynamic "custom_oauth2_provider_config" {
      for_each = each.value.vendor == "CustomOauth2" ? [each.value] : []
      content {
        client_id_wo                  = lookup(var.oauth2_client_ids, each.key, null)
        client_secret_wo              = lookup(var.oauth2_client_secrets, each.key, null)
        client_credentials_wo_version = custom_oauth2_provider_config.value.credentials_version

        oauth_discovery {
          discovery_url = custom_oauth2_provider_config.value.discovery_url

          dynamic "authorization_server_metadata" {
            for_each = custom_oauth2_provider_config.value.discovery_url == null ? [custom_oauth2_provider_config.value] : []
            content {
              issuer                 = authorization_server_metadata.value.issuer
              authorization_endpoint = authorization_server_metadata.value.authorization_endpoint
              token_endpoint         = authorization_server_metadata.value.token_endpoint
              response_types         = authorization_server_metadata.value.response_types
            }
          }
        }
      }
    }

    dynamic "github_oauth2_provider_config" {
      for_each = each.value.vendor == "GithubOauth2" ? [each.value] : []
      content {
        client_id_wo                  = lookup(var.oauth2_client_ids, each.key, null)
        client_secret_wo              = lookup(var.oauth2_client_secrets, each.key, null)
        client_credentials_wo_version = github_oauth2_provider_config.value.credentials_version
      }
    }

    dynamic "google_oauth2_provider_config" {
      for_each = each.value.vendor == "GoogleOauth2" ? [each.value] : []
      content {
        client_id_wo                  = lookup(var.oauth2_client_ids, each.key, null)
        client_secret_wo              = lookup(var.oauth2_client_secrets, each.key, null)
        client_credentials_wo_version = google_oauth2_provider_config.value.credentials_version
      }
    }

    dynamic "microsoft_oauth2_provider_config" {
      for_each = each.value.vendor == "Microsoft" ? [each.value] : []
      content {
        client_id_wo                  = lookup(var.oauth2_client_ids, each.key, null)
        client_secret_wo              = lookup(var.oauth2_client_secrets, each.key, null)
        client_credentials_wo_version = microsoft_oauth2_provider_config.value.credentials_version
      }
    }

    dynamic "salesforce_oauth2_provider_config" {
      for_each = each.value.vendor == "SalesforceOauth2" ? [each.value] : []
      content {
        client_id_wo                  = lookup(var.oauth2_client_ids, each.key, null)
        client_secret_wo              = lookup(var.oauth2_client_secrets, each.key, null)
        client_credentials_wo_version = salesforce_oauth2_provider_config.value.credentials_version
      }
    }

    dynamic "slack_oauth2_provider_config" {
      for_each = each.value.vendor == "SlackOauth2" ? [each.value] : []
      content {
        client_id_wo                  = lookup(var.oauth2_client_ids, each.key, null)
        client_secret_wo              = lookup(var.oauth2_client_secrets, each.key, null)
        client_credentials_wo_version = slack_oauth2_provider_config.value.credentials_version
      }
    }
  }

  depends_on = [terraform_data.validations]
}

resource "aws_bedrockagentcore_token_vault_cmk" "this" {
  count = var.token_vault_cmk == null ? 0 : 1

  token_vault_id = var.token_vault_cmk.token_vault_id

  kms_configuration {
    key_type    = var.token_vault_cmk.key_type
    kms_key_arn = var.token_vault_cmk.kms_key_arn
  }
}
