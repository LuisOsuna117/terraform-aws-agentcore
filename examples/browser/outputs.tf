output "browsers" {
  description = "Created Browser identifiers keyed by logical name."
  value       = module.agentcore.browsers
}

output "browser_profiles" {
  description = "Created Browser Profile identifiers keyed by logical name."
  value       = module.agentcore.browser_profiles
}
