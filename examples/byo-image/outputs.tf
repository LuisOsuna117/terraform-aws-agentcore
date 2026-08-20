output "agent_runtime_arn" {
  description = "ARN of the AgentCore runtime."
  value       = module.agentcore.agent_runtime_arn
}

output "effective_image_uri" {
  description = "The image URI used by the runtime."
  value       = module.agentcore.effective_image_uri
}

output "execution_role_arn" {
  description = "ARN of the execution role."
  value       = module.agentcore.execution_role_arn
}
