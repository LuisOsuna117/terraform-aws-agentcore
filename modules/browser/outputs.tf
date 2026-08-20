output "browser_id" {
  description = "Browser ID, or null in profile-only mode."
  value       = var.create_browser ? aws_bedrockagentcore_browser.this[0].browser_id : null
}

output "browser_arn" {
  description = "Browser ARN, or null in profile-only mode."
  value       = var.create_browser ? aws_bedrockagentcore_browser.this[0].browser_arn : null
}

output "profile_ids" {
  description = "Browser Profile IDs keyed by caller-defined name."
  value       = { for key, profile in aws_bedrockagentcore_browser_profile.this : key => profile.profile_id }
}

output "profile_arns" {
  description = "Browser Profile ARNs keyed by caller-defined name."
  value       = { for key, profile in aws_bedrockagentcore_browser_profile.this : key => profile.profile_arn }
}
