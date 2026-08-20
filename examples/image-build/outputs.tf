output "image_uri" {
  description = "ECR image URI produced by the build pipeline."
  value       = module.agentcore.image_builds["agent"].image_uri
}

output "codebuild_project_name" {
  description = "CodeBuild project that builds the agent image."
  value       = module.agentcore.image_builds["agent"].codebuild_project_name
}

output "codebuild_start_build_command" {
  description = "Command that starts a build when apply-time triggering is disabled."
  value       = module.agentcore.image_builds["agent"].codebuild_start_build_command
}
