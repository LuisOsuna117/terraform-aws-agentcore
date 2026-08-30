output "target_id" {
  description = "Created Gateway Runtime target ID."
  value       = try(aws_cloudformation_stack.this.outputs["TargetId"], null)
}

output "gateway_arn" {
  description = "ARN of the Gateway that owns the Runtime target."
  value       = try(aws_cloudformation_stack.this.outputs["GatewayArn"], null)
}
