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

output "workload_identity_arn" {
  description = "Workload identity ARN for the runtime. Use this to grant callers permission to invoke the runtime via AgentCore workload tokens."
  value       = try(aws_bedrockagentcore_agent_runtime.this.workload_identity_details[0].workload_identity_arn, null)
}
