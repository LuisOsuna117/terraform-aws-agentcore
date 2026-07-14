output "gateway_url" {
  description = "URL endpoint of the AgentCore Gateway."
  value       = module.agentcore.gateway_url
}

output "gateway_target_ids" {
  description = "Map of target keys to Gateway target IDs."
  value       = module.agentcore.gateway_target_ids
}

output "gateway_protocol_type" {
  description = "Effective aggregation protocol; null for this general HTTP gateway."
  value       = module.agentcore.gateway_protocol_type
}

output "gateway_agent_target_invocation_urls" {
  description = "Map of AGENT target keys to Gateway invocation URLs."
  value       = module.agentcore.gateway_agent_target_invocation_urls
}
