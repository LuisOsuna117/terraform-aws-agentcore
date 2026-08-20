output "workload_identity_arn" {
  description = "Created AgentCore workload identity ARN."
  value       = module.agentcore.workload_identities["application"]
}

output "oauth2_credential_provider_arn" {
  description = "Created AgentCore OAuth2 credential provider ARN."
  value       = module.agentcore.oauth2_credential_providers["external_api"]
}
