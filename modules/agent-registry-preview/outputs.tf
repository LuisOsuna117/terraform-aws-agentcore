output "registry_id" {
  value = try(aws_cloudformation_stack.this.outputs["RegistryId"], null)
}

output "registry_arn" {
  value = try(aws_cloudformation_stack.this.outputs["RegistryArn"], null)
}
