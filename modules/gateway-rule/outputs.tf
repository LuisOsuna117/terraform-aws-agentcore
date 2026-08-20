output "rule_id" {
  description = "Created Gateway Rule ID."
  value       = aws_bedrockagentcore_gateway_rule.this.rule_id
}

output "gateway_arn" {
  description = "ARN of the Gateway that owns this rule."
  value       = aws_bedrockagentcore_gateway_rule.this.gateway_arn
}
