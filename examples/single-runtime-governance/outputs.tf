output "runtime_arn" {
  description = "ARN of the AgentCore Runtime created by this module invocation."
  value       = module.agentcore.agent_runtime_arn
}

output "gateway_url" {
  description = "URL of the AgentCore Gateway created by this module invocation."
  value       = module.agentcore.gateway_url
}

output "policy_engine_arn" {
  description = "ARN of the Policy Engine attached to the Gateway."
  value       = module.agentcore.policy_engine_arn
}
