# ==============================================================================
# Gateway
# ==============================================================================

output "gateway_id" {
  description = "Unique identifier of the AgentCore Gateway."
  value       = aws_bedrockagentcore_gateway.this.gateway_id
}

output "gateway_arn" {
  description = "ARN of the AgentCore Gateway."
  value       = aws_bedrockagentcore_gateway.this.gateway_arn
}

output "gateway_url" {
  description = "URL endpoint for the AgentCore Gateway."
  value       = aws_bedrockagentcore_gateway.this.gateway_url
}

output "gateway_protocol_type" {
  description = "Effective Gateway aggregation protocol. MCP for aggregation gateways, null for general HTTP gateways."
  value       = local.effective_protocol_type
}

output "workload_identity_arn" {
  description = "ARN of the workload identity associated with the gateway."
  value       = try(aws_bedrockagentcore_gateway.this.workload_identity_details[0].workload_identity_arn, null)
}

output "gateway_target_ids" {
  description = "Map of target keys to AgentCore Gateway target IDs."
  value = merge(
    { for key, stack in aws_cloudformation_stack.gateway_target : key => try(stack.outputs["TargetId"], null) },
    { for key, stack in aws_cloudformation_stack.agent_gateway_target : key => try(stack.outputs["TargetId"], null) },
  )
}

output "gateway_target_endpoints" {
  description = "Map of MCP target keys to the resolved MCP server endpoints configured on the gateway targets."
  value       = local.mcp_target_endpoints
}

output "gateway_agent_target_invocation_urls" {
  description = "Map of AGENT target keys to their path-routed Gateway invocation URLs."
  value = {
    for key in keys(local.agent_targets) :
    key => "${trimsuffix(aws_bedrockagentcore_gateway.this.gateway_url, "/")}/${local.target_names[key]}/invocations"
  }
}

# ==============================================================================
# IAM
# ==============================================================================

output "role_arn" {
  description = "ARN of the IAM role used by the gateway. Equals var.role_arn when create_role = false."
  value       = local.role_arn
}

output "role_name" {
  description = "Name of the module-created gateway IAM role. Empty string when create_role = false."
  value       = var.create_role ? aws_iam_role.gateway[0].name : ""
}
