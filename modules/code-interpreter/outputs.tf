output "code_interpreter_id" {
  description = "Unique identifier of the AgentCore Code Interpreter."
  value       = aws_bedrockagentcore_code_interpreter.this.code_interpreter_id
}

output "code_interpreter_arn" {
  description = "ARN of the AgentCore Code Interpreter."
  value       = aws_bedrockagentcore_code_interpreter.this.code_interpreter_arn
}

output "code_interpreter_name" {
  description = "Resolved name of the AgentCore Code Interpreter."
  value       = var.name
}

output "execution_role_arn" {
  description = "ARN of the IAM execution role used by the Code Interpreter."
  value       = var.execution_role_arn
}
