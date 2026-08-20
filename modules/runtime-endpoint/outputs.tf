output "agent_runtime_endpoint_arn" {
  description = "AgentCore Runtime Endpoint ARN."
  value       = aws_bedrockagentcore_agent_runtime_endpoint.this.agent_runtime_endpoint_arn
}

output "agent_runtime_arn" {
  description = "ARN of the Runtime associated with this endpoint."
  value       = aws_bedrockagentcore_agent_runtime_endpoint.this.agent_runtime_arn
}
