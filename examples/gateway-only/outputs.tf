output "gateway_id" {
  description = "Unique identifier of the AgentCore Gateway."
  value       = module.agentcore.gateway_id
}

output "gateway_url" {
  description = "URL endpoint of the AgentCore Gateway."
  value       = module.agentcore.gateway_url
}

output "gateway_role_arn" {
  description = "ARN of the IAM role used by the gateway."
  value       = module.agentcore.gateway_role_arn
}
