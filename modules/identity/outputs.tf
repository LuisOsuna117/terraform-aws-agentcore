output "workload_identity_arns" {
  description = "Workload identity ARNs keyed by caller-defined name."
  value       = { for key, identity in aws_bedrockagentcore_workload_identity.this : key => identity.workload_identity_arn }
}

output "api_key_credential_provider_arns" {
  description = "API key credential provider ARNs keyed by caller-defined name. Secret values are never returned."
  value       = { for key, provider in aws_bedrockagentcore_api_key_credential_provider.this : key => provider.credential_provider_arn }
}

output "oauth2_credential_provider_arns" {
  description = "OAuth2 credential provider ARNs keyed by caller-defined name. Client credentials are never returned."
  value       = { for key, provider in aws_bedrockagentcore_oauth2_credential_provider.this : key => provider.credential_provider_arn }
}

output "token_vault_id" {
  description = "Configured token vault ID, or null when token_vault_cmk is not set."
  value       = var.token_vault_cmk == null ? null : var.token_vault_cmk.token_vault_id
}
