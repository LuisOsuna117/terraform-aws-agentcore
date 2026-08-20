output "harness_id" {
  description = "Managed Harness ID."
  value       = aws_bedrockagentcore_harness.this.harness_id
}

output "harness_arn" {
  description = "Managed Harness ARN."
  value       = aws_bedrockagentcore_harness.this.arn
}
