output "registry_id" {
  description = "Agent Registry identifier when returned by the preview API."
  value       = try(aws_cloudformation_stack.this.outputs["RegistryId"], null)
}

output "registry_arn" {
  description = "Agent Registry ARN when returned by the preview API."
  value       = try(aws_cloudformation_stack.this.outputs["RegistryArn"], null)
}
