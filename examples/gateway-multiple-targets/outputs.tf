output "gateway_url" {
  description = "URL endpoint of the AgentCore Gateway."
  value       = module.agentcore.gateway_url
}

output "gateway_target_ids" {
  description = "Map of MCP target keys to Gateway target IDs."
  value       = module.agentcore.gateway_target_ids
}

output "gateway_target_endpoints" {
  description = "Map of MCP target keys to resolved MCP server endpoints."
  value       = module.agentcore.gateway_target_endpoints
}
