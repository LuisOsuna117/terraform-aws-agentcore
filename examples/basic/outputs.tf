output "agent_runtime_arn" {
  description = "ARN of the provisioned AgentCore runtime."
  value       = module.agentcore.agent_runtime_arn
}

output "agent_runtime_id" {
  description = "ID of the provisioned AgentCore runtime."
  value       = module.agentcore.agent_runtime_id
}

output "agent_runtime_name" {
  description = "Resolved name of the AgentCore runtime."
  value       = module.agentcore.agent_runtime_name
}

output "container_image_uri" {
  description = "Full container image URI deployed to the runtime."
  value       = module.agentcore.container_image_uri
}

output "ecr_repository_url" {
  description = "ECR repository URL — use this to push new images manually."
  value       = module.agentcore.ecr_repository_url
}

output "execution_role_arn" {
  description = "ARN of the IAM execution role used by the runtime."
  value       = module.agentcore.execution_role_arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project — trigger a manual build from here."
  value       = module.agentcore.codebuild_project_name
}
