# ==============================================================================
# AgentCore Runtime
# ==============================================================================

output "agent_runtime_id" {
  description = "ID of the AgentCore runtime resource."
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_id
}

output "agent_runtime_arn" {
  description = "ARN of the AgentCore runtime. Use this to grant invoke permissions to callers."
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_arn
}

output "agent_runtime_name" {
  description = "Resolved name of the AgentCore runtime as registered with the Bedrock AgentCore API."
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_name
}

output "agent_runtime_version" {
  description = "Version identifier of the deployed AgentCore runtime."
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_version
}

output "agent_runtime_network_mode" {
  description = "Network mode of the runtime (PUBLIC or PRIVATE)."
  value       = var.network_mode
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
  description = "ARN of the IAM role used by the CodeBuild image-build project."
  value       = aws_iam_role.image_build.arn
}

# ==============================================================================
# ECR
# ==============================================================================

output "ecr_repository_url" {
  description = "Full ECR repository URL (without tag). Use as the base for docker push/pull commands."
  value       = aws_ecr_repository.this.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.this.arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository as registered in the AWS account."
  value       = aws_ecr_repository.this.name
}

output "container_image_uri" {
  description = "Full container image URI (repository URL + tag) deployed to the runtime."
  value       = "${aws_ecr_repository.this.repository_url}:${var.image_tag}"
}

# ==============================================================================
# CodeBuild
# ==============================================================================

output "codebuild_project_name" {
  description = "Name of the CodeBuild project used to build and push the agent image."
  value       = aws_codebuild_project.agent_image.name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project."
  value       = aws_codebuild_project.agent_image.arn
}

# ==============================================================================
# S3 — Source Bucket
# ==============================================================================

output "source_bucket_name" {
  description = "Name of the S3 bucket holding the agent source code archive."
  value       = aws_s3_bucket.agent_source.id
}

output "source_bucket_arn" {
  description = "ARN of the S3 source bucket."
  value       = aws_s3_bucket.agent_source.arn
}

output "source_object_key" {
  description = "S3 object key for the currently uploaded agent source code archive."
  value       = aws_s3_object.agent_source.key
}

output "source_code_md5" {
  description = "MD5 hash of the agent source code archive. Changes when source files change and triggers a new CodeBuild run."
  value       = data.archive_file.agent_source.output_md5
}
