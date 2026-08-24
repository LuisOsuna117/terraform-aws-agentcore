output "target_id" {
  description = "Created Gateway connector target ID."
  value       = try(aws_cloudformation_stack.this.outputs["TargetId"], null)
}

output "gateway_arn" {
  description = "ARN of the Gateway that owns the connector target."
  value       = try(aws_cloudformation_stack.this.outputs["GatewayArn"], local.gateway_arn)
}

output "connector_id" {
  description = "Configured built-in connector identifier."
  value       = var.connector_id
}

output "connector_version" {
  description = "Pinned built-in connector version."
  value       = var.connector_version
}
