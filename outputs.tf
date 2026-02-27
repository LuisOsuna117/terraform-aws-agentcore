# ==============================================================================
# AgentCore Runtime
# ==============================================================================

output "agent_runtime_id" {
  description = "ID of the AgentCore runtime resource. Null when create_runtime = false."
  value       = var.create_runtime ? module.runtime[0].agent_runtime_id : null
}

output "agent_runtime_arn" {
  description = "ARN of the AgentCore runtime. Use this to grant invoke permissions to callers. Null when create_runtime = false."
  value       = var.create_runtime ? module.runtime[0].agent_runtime_arn : null
}

output "agent_runtime_name" {
  description = "Resolved name of the AgentCore runtime as registered with the Bedrock AgentCore API. Null when create_runtime = false."
  value       = var.create_runtime ? module.runtime[0].agent_runtime_name : null
}

output "agent_runtime_version" {
  description = "Version identifier of the deployed AgentCore runtime. Null when create_runtime = false."
  value       = var.create_runtime ? module.runtime[0].agent_runtime_version : null
}

output "agent_runtime_network_mode" {
  description = "Network mode of the runtime (PUBLIC or PRIVATE). Null when create_runtime = false."
  value       = var.create_runtime ? var.network_mode : null
}

# ==============================================================================
# Image
# ==============================================================================

output "effective_image_uri" {
  description = "The container image URI used by the runtime. When create_build_pipeline = true this is the ECR repo URL + image_tag; when create_build_pipeline = false this is the caller-supplied image_uri."
  value       = local.effective_image_uri
}

# Backwards-compatible alias kept for existing callers.
output "container_image_uri" {
  description = "Alias for effective_image_uri. Kept for backwards compatibility."
  value       = local.effective_image_uri
}

# ==============================================================================
# IAM
# ==============================================================================

output "execution_role_arn" {
  description = "ARN of the IAM role used by the AgentCore runtime. Will equal var.execution_role_arn when create_execution_role = false."
  value       = local.execution_role_arn
}

output "execution_role_name" {
  description = "Name of the module-created execution role. Empty string when create_execution_role = false."
  value       = var.create_execution_role ? aws_iam_role.agent_execution[0].name : ""
}

output "codebuild_role_arn" {
  description = "ARN of the IAM role used by the CodeBuild image-build project. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].codebuild_role_arn : null
}

# ==============================================================================
# ECR (create_build_pipeline = true only)
# ==============================================================================

output "ecr_repository_url" {
  description = "Full ECR repository URL (without tag). Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].ecr_repository_url : null
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].ecr_repository_arn : null
}

output "ecr_repository_name" {
  description = "Name of the ECR repository. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].ecr_repository_name : null
}

# ==============================================================================
# CodeBuild (create_build_pipeline = true only)
# ==============================================================================

output "codebuild_project_name" {
  description = "Name of the CodeBuild project. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].codebuild_project_name : null
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].codebuild_project_arn : null
}

# ==============================================================================
# S3 — Source Bucket (create_build_pipeline = true only)
# ==============================================================================

output "source_bucket_name" {
  description = "Name of the S3 bucket holding the agent source code archive. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].source_bucket_name : null
}

output "source_bucket_arn" {
  description = "ARN of the S3 source bucket. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].source_bucket_arn : null
}
