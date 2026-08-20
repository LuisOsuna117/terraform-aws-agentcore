output "runtimes" {
  description = "Created Runtime identifiers keyed by logical name."
  value       = module.agentcore.runtimes
}

output "gateways" {
  description = "Created Gateway identifiers and URLs keyed by logical name."
  value       = module.agentcore.gateways
}

output "gateway_targets" {
  description = "Created Gateway target identifiers keyed by logical name."
  value       = module.agentcore.gateway_targets
}
