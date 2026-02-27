# ==============================================================================
# Core
# ==============================================================================

variable "name" {
  description = "Base name prefix shared with the root module."
  type        = string
}

variable "common_tags" {
  description = "Pre-merged tag map passed from the root module."
  type        = map(string)
  default     = {}
}

# ==============================================================================
# ECR
# ==============================================================================

variable "ecr_repository_name" {
  description = "Name of the ECR repository. Passed as the resolved local from the root."
  type        = string
}

variable "ecr_image_tag_mutability" {
  description = "Tag mutability setting for the ECR repository."
  type        = string
  default     = "MUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Enable automatic vulnerability scanning on image push."
  type        = bool
  default     = true
}

variable "ecr_lifecycle_keep_count" {
  description = "Number of most-recent images to retain."
  type        = number
  default     = 10
}

variable "ecr_force_delete" {
  description = "Destroy the ECR repository even when it contains images."
  type        = bool
  default     = false
}

variable "ecr_pull_principals" {
  description = "List of IAM principal ARNs allowed to pull images from the ECR repository. When empty (default), only the current account root is allowed, preserving the previous behaviour. Extend this list to enable cross-account or cross-org pulls."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for p in var.ecr_pull_principals : can(regex("^arn:aws[^:]*:", p))])
    error_message = "Each entry in ecr_pull_principals must be a valid ARN starting with arn:aws."
  }
}

# ==============================================================================
# S3 — Agent Source
# ==============================================================================

variable "agent_source_dir" {
  description = "Resolved path to the agent application directory."
  type        = string
}

variable "source_bucket_force_destroy" {
  description = "Destroy the S3 source bucket even when it contains objects."
  type        = bool
  default     = false
}

# ==============================================================================
# CodeBuild
# ==============================================================================

variable "image_tag" {
  description = "Docker image tag to build and push."
  type        = string
  default     = "latest"
}

variable "codebuild_compute_type" {
  description = "Compute type for the CodeBuild environment."
  type        = string
  default     = "BUILD_GENERAL1_LARGE"
}

variable "codebuild_environment_image" {
  description = "Docker image used for the CodeBuild build environment."
  type        = string
  default     = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
}

variable "codebuild_environment_type" {
  description = "CodeBuild environment type."
  type        = string
  default     = "ARM_CONTAINER"
}

variable "codebuild_build_timeout" {
  description = "Maximum build duration in minutes."
  type        = number
  default     = 60
}

variable "trigger_build_on_apply" {
  description = "When true, automatically starts a CodeBuild run on every terraform apply where source or configuration changes."
  type        = bool
  default     = true
}
