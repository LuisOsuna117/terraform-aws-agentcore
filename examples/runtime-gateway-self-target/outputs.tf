output "agent_runtime_arn" {
  description = "ARN of the module-created AgentCore Runtime."
  value       = module.agentcore.agent_runtime_arn
}

output "gateway_url" {
  description = "URL endpoint of the AgentCore Gateway."
  value       = module.agentcore.gateway_url
}

output "gateway_runtime_target_id" {
  description = "Gateway target ID for the module-created runtime target."
  value       = module.agentcore.gateway_runtime_target_id
}

output "gateway_target_endpoints" {
  description = "Map of MCP target keys to resolved MCP server endpoints."
  value       = module.agentcore.gateway_target_endpoints
}
