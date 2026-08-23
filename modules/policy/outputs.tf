output "policy_engine_id" {
  description = "Created or caller-supplied policy engine ID."
  value       = local.policy_engine_id
}

output "policy_engine_arn" {
  description = "Created policy engine ARN, or null when an existing engine is used."
  value       = var.create_policy_engine ? aws_bedrockagentcore_policy_engine.this[0].policy_engine_arn : null
}

output "policy_arns" {
  description = "Policy ARNs keyed by caller-defined name."
  value       = { for key, policy in aws_bedrockagentcore_policy.this : key => policy.policy_arn }
}

output "resource_policies" {
  description = "Configured AgentCore resource policies keyed by caller-defined name."
  value       = var.resource_policies
}
