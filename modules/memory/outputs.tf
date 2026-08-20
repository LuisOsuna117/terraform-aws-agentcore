output "memory_arn" {
  description = "ARN of the AgentCore Memory resource."
  value       = aws_bedrockagentcore_memory.this.arn
}

output "memory_id" {
  description = "Unique identifier of the AgentCore Memory resource."
  value       = aws_bedrockagentcore_memory.this.id
}

output "memory_name" {
  description = "Name of the AgentCore Memory resource."
  value       = aws_bedrockagentcore_memory.this.name
}
