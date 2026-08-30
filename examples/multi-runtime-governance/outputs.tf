output "interactive_gateway_url" {
  description = "JWT-authorized Gateway URL for interactive callers."
  value       = module.agentcore.gateway_url
}

output "automation_gateway_url" {
  description = "IAM-authorized Gateway URL for automation callers."
  value       = module.agentcore.additional_gateways["automation"].url
}

output "runtimes" {
  description = "Primary and additional Runtime identifiers."
  value = {
    interactive = {
      id  = module.agentcore.agent_runtime_id
      arn = module.agentcore.agent_runtime_arn
    }
    automation = module.agentcore.additional_agent_runtimes["automation"]
  }
}

output "policy_engine_arn" {
  description = "Policy Engine observed by both Gateways."
  value       = module.agentcore.policy_engine_arn
}
