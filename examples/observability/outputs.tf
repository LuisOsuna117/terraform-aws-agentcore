output "observability_log_groups" {
  description = "Created observability log group ARNs keyed by logical name."
  value       = module.agentcore.observability_log_groups
}
