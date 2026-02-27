output "agent_runtime_id" {
  description = "ID of the AgentCore runtime resource."
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_id
}

output "agent_runtime_arn" {
  description = "ARN of the AgentCore runtime."
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_arn
}

output "agent_runtime_name" {
  description = "Resolved name of the AgentCore runtime."
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_name
}

output "agent_runtime_version" {
  description = "Version identifier of the deployed AgentCore runtime."
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_version
}
