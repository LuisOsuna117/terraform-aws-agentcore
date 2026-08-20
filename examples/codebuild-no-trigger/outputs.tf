output "codebuild_project_name" {
  description = "Name of the CodeBuild project. Trigger a build with: aws codebuild start-build --project-name <value>"
  value       = module.agentcore.codebuild_project_name
}

output "codebuild_start_build_command" {
  description = "AWS CLI command that starts the CodeBuild project."
  value       = module.agentcore.codebuild_start_build_command
}

output "ecr_repository_url" {
  description = "ECR repository URL. Push images here before invoking the runtime."
  value       = module.agentcore.ecr_repository_url
}

output "effective_image_uri" {
  description = "Image URI the optional second-phase Runtime will use."
  value       = module.agentcore.effective_image_uri
}
