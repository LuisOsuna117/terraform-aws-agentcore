output "policy_arns" {
  description = "Temporal Policy ARNs keyed by caller-defined name."
  value       = { for key, policy in awscc_bedrockagentcore_policy.this : key => policy.policy_arn }
}
