# ==============================================================================
# Core Identification
# ==============================================================================

variable "name" {
  description = "Base name used as a prefix for all resources created by this module (e.g. \"my-agent\"). Must start with a letter, max 32 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,31}$", var.name))
    error_message = "name must start with a letter, be max 32 characters, and contain only letters, numbers, and hyphens."
  }
}

variable "runtime_name" {
  description = "Override for the AgentCore runtime resource name. Defaults to var.name when null. Hyphens are automatically converted to underscores to satisfy the AgentCore API."
  type        = string
  default     = null

  validation {
    condition     = var.runtime_name == null || can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,47}$", var.runtime_name))
    error_message = "runtime_name must start with a letter, be max 48 characters, and contain only letters, numbers, hyphens, or underscores."
  }
}

variable "description" {
  description = "Human-readable description attached to the AgentCore runtime resource."
  type        = string
  default     = "Managed by terraform-aws-agentcore."
}

variable "tags" {
  description = "Map of tags to apply to all taggable resources. Merged with module-level defaults."
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Runtime Configuration
# ==============================================================================

variable "network_mode" {
  description = "Network mode for the AgentCore runtime. PUBLIC exposes the runtime endpoint on the public internet; PRIVATE keeps it internal to your VPC."
  type        = string
  default     = "PUBLIC"

  validation {
    condition     = contains(["PUBLIC", "PRIVATE"], var.network_mode)
    error_message = "network_mode must be either \"PUBLIC\" or \"PRIVATE\"."
  }
}

variable "create_build_pipeline" {
  description = "When true (default), creates the full CodeBuild build pipeline: ECR repository, S3 source bucket, and CodeBuild project. Set to false to use a pre-built image via image_uri (Bring Your Own Image)."
  type        = bool
  default     = true
}

variable "create_runtime" {
  description = "When true (default), creates the AgentCore runtime resource. Set to false to provision only the build pipeline infrastructure without a runtime (useful for pre-baking images before the runtime is ready)."
  type        = bool
  default     = true
}

variable "image_uri" {
  description = "Full container image URI (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-agent:v1.2.3) to deploy to the runtime. Required when create_build_pipeline = false. Must be null when create_build_pipeline = true."
  type        = string
  default     = null
}

variable "trigger_build_on_apply" {
  description = "When true (default) and create_build_pipeline = true, a CodeBuild run is automatically started on every apply where source code, image_tag, or ECR configuration changes. Set to false to manage builds out-of-band (CI/CD pipeline, manual console run). Ignored when create_build_pipeline = false."
  type        = bool
  default     = true
}

variable "image_tag" {
  description = "Docker image tag to deploy to the AgentCore runtime. Used as the tag appended to the ECR image URI in codebuild mode. Changing this triggers a new CodeBuild run when trigger_build_on_apply = true."
  type        = string
  default     = "latest"
}

variable "environment_variables" {
  description = "Additional environment variables injected into the AgentCore runtime process. AWS_REGION and AWS_DEFAULT_REGION are always set automatically."
  type        = map(string)
  default     = {}
}

# ==============================================================================
# IAM — Execution Role
# ==============================================================================

variable "create_execution_role" {
  description = "When true, the module creates an IAM execution role for the AgentCore runtime. Set to false to provide an existing role via execution_role_arn."
  type        = bool
  default     = true
}

variable "execution_role_arn" {
  description = "ARN of an existing IAM role to use as the AgentCore runtime execution role. Required when create_execution_role = false."
  type        = string
  default     = null
}

variable "attach_bedrock_fullaccess_policy" {
  description = "When true and create_execution_role = true, attaches the AWS-managed BedrockAgentCoreFullAccess policy to the execution role. Set to false if you prefer a least-privilege-only setup via additional_iam_statements."
  type        = bool
  default     = true
}

variable "additional_iam_statements" {
  description = "Additional IAM policy statements to append to the inline policy on the execution role. Use this to grant access to Bedrock models, Secrets Manager, or other services your agent code requires."
  type        = list(any)
  default     = []
}

# ==============================================================================
# ECR
# ==============================================================================

variable "ecr_repository_name" {
  description = "Name of the ECR repository that holds agent container images. Defaults to var.name when null."
  type        = string
  default     = null

  validation {
    condition     = var.ecr_repository_name == null || can(regex("^[a-z0-9][a-z0-9._-]{0,255}$", var.ecr_repository_name))
    error_message = "ecr_repository_name must be lowercase, start with a letter or digit, and be at most 256 characters."
  }
}

variable "ecr_image_tag_mutability" {
  description = "Tag mutability setting for the ECR repository. IMMUTABLE is recommended for production to prevent image overwrites."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "ecr_image_tag_mutability must be either \"MUTABLE\" or \"IMMUTABLE\"."
  }
}

variable "ecr_scan_on_push" {
  description = "Enable automatic vulnerability scanning when an image is pushed to the ECR repository."
  type        = bool
  default     = true
}

variable "ecr_lifecycle_keep_count" {
  description = "Number of most-recent images to retain in the ECR repository. Older images are expired automatically."
  type        = number
  default     = 10

  validation {
    condition     = var.ecr_lifecycle_keep_count >= 1
    error_message = "ecr_lifecycle_keep_count must be at least 1."
  }
}

variable "ecr_force_delete" {
  description = "Allow the ECR repository to be deleted even if it contains images. Useful in non-production environments. Defaults to false for safety."
  type        = bool
  default     = false
}

# ==============================================================================
# S3 — Agent Source
# ==============================================================================

variable "agent_source_dir" {
  description = "Absolute or module-relative path to the directory containing your agent application code. The directory is zipped and uploaded to S3 for CodeBuild to consume."
  type        = string
  default     = null # resolved in locals to "${path.module}/agent-code"
}

variable "source_bucket_force_destroy" {
  description = "Allow the S3 source bucket to be destroyed even if it contains objects. Useful in non-production environments. Defaults to false for safety."
  type        = bool
  default     = false
}

# ==============================================================================
# CodeBuild
# ==============================================================================

variable "codebuild_compute_type" {
  description = "Compute type for the CodeBuild environment. See https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html"
  type        = string
  default     = "BUILD_GENERAL1_LARGE"

  validation {
    condition = contains([
      "BUILD_GENERAL1_SMALL", "BUILD_GENERAL1_MEDIUM", "BUILD_GENERAL1_LARGE",
      "BUILD_GENERAL1_XLARGE", "BUILD_GENERAL1_2XLARGE",
      "BUILD_LAMBDA_1GB", "BUILD_LAMBDA_2GB", "BUILD_LAMBDA_4GB", "BUILD_LAMBDA_8GB", "BUILD_LAMBDA_10GB"
    ], var.codebuild_compute_type)
    error_message = "codebuild_compute_type is not a recognised CodeBuild compute type."
  }
}

variable "codebuild_environment_image" {
  description = "Docker image used for the CodeBuild build environment."
  type        = string
  default     = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
}

variable "codebuild_environment_type" {
  description = "CodeBuild environment type. Should match the architecture of codebuild_environment_image (e.g. ARM_CONTAINER for aarch64 images)."
  type        = string
  default     = "ARM_CONTAINER"

  validation {
    condition     = contains(["LINUX_CONTAINER", "LINUX_GPU_CONTAINER", "ARM_CONTAINER", "WINDOWS_CONTAINER", "WINDOWS_SERVER_2019_CONTAINER"], var.codebuild_environment_type)
    error_message = "codebuild_environment_type must be a valid CodeBuild environment type."
  }
}

variable "codebuild_build_timeout" {
  description = "Maximum duration (in minutes) for a CodeBuild build before it is terminated."
  type        = number
  default     = 60

  validation {
    condition     = var.codebuild_build_timeout >= 5 && var.codebuild_build_timeout <= 480
    error_message = "codebuild_build_timeout must be between 5 and 480 minutes."
  }
}
