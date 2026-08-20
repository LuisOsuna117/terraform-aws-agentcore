output "policy_engine_arn" {
  description = "Created AgentCore Policy Engine ARN."
  value       = module.policy.policy_engine_arn
}

output "policy_arns" {
  description = "Created AgentCore policy ARNs."
  value       = module.policy.policy_arns
}
