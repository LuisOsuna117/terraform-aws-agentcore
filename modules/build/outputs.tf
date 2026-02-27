# ==============================================================================
# ECR
# ==============================================================================

output "ecr_repository_url" {
  description = "Full ECR repository URL (without tag)."
  value       = aws_ecr_repository.this.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.this.arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.this.name
}

# Convenience: the full image URI (repository URL + tag) produced by this build.
output "image_uri" {
  description = "Full container image URI (ecr_repository_url:image_tag) that this build pipeline produces."
  value       = "${aws_ecr_repository.this.repository_url}:${var.image_tag}"
}

# ==============================================================================
# CodeBuild
# ==============================================================================

output "codebuild_project_name" {
  description = "Name of the CodeBuild project."
  value       = aws_codebuild_project.agent_image.name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project."
  value       = aws_codebuild_project.agent_image.arn
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild service role."
  value       = aws_iam_role.image_build.arn
}

# ==============================================================================
# S3
# ==============================================================================

output "source_bucket_name" {
  description = "Name of the S3 bucket holding the agent source code."
  value       = aws_s3_bucket.agent_source.id
}

output "source_bucket_arn" {
  description = "ARN of the S3 source bucket."
  value       = aws_s3_bucket.agent_source.arn
}

# ==============================================================================
# Operational helpers
# ==============================================================================

output "codebuild_start_build_command" {
  description = "AWS CLI command to trigger a build manually. Useful for CI pipelines when trigger_build_on_apply = false."
  value       = "aws codebuild start-build --project-name ${aws_codebuild_project.agent_image.name} --region ${data.aws_region.current.id}"
}
