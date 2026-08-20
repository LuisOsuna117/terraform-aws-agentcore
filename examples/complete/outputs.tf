output "runtimes" {
  description = "Created Runtime identifiers keyed by logical name."
  value       = module.agentcore.runtimes
}

output "gateways" {
  description = "Created Gateway identifiers and URLs keyed by logical name."
  value       = module.agentcore.gateways
}

output "workload_identities" {
  description = "Created AgentCore workload identity ARNs."
  value       = module.agentcore.workload_identities
}
