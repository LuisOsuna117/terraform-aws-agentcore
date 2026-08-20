output "browser_arn" {
  description = "Created Browser ARN."
  value       = module.browser.browser_arn
}

output "profile_arns" {
  description = "Created Browser Profile ARNs."
  value       = module.browser.profile_arns
}
