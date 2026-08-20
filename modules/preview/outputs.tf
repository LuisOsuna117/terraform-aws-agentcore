output "stack_id" {
  description = "CloudFormation stack identifier."
  value       = aws_cloudformation_stack.this.id
}

output "outputs" {
  description = "CloudFormation stack outputs."
  value       = aws_cloudformation_stack.this.outputs
}
