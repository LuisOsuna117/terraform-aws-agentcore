output "memories" {
  description = "Created Memory identifiers keyed by logical name."
  value       = module.agentcore.memories
}

output "memory_strategies" {
  description = "Created Memory strategy identifiers keyed by logical name."
  value       = module.agentcore.memory_strategies
}
