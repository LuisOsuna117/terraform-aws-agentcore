output "workload_identity_arns" {
  description = "Created workload identity ARNs."
  value       = module.identity.workload_identity_arns
}

output "api_key_credential_provider_arns" {
  description = "Created API-key credential provider ARNs."
  value       = module.identity.api_key_credential_provider_arns
}

output "oauth2_credential_provider_arns" {
  description = "Created OAuth2 credential provider ARNs."
  value       = module.identity.oauth2_credential_provider_arns
}
