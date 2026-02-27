output "agent_runtime_arn" {
  description = "ARN of the AgentCore runtime."
  value       = module.agentcore.agent_runtime_arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project. Trigger a build with: aws codebuild start-build --project-name <value>"
  value       = module.agentcore.codebuild_project_name
}

output "ecr_repository_url" {
  description = "ECR repository URL. Push images here before invoking the runtime."
  value       = module.agentcore.ecr_repository_url
}

output "effective_image_uri" {
  description = "The image URI configured on the runtime."
  value       = module.agentcore.effective_image_uri
}
