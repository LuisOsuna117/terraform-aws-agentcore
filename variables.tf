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

variable "allow_bedrock_invoke_all" {
  description = "When true (default), the inline execution role policy includes bedrock:InvokeModel and bedrock:InvokeModelWithResponseStream on Resource \"*\". Set to false to remove this broad statement and supply model-specific permissions via additional_iam_statements (recommended for production)."
  type        = bool
  default     = true
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

variable "ecr_pull_principals" {
  description = "List of IAM principal ARNs allowed to pull images from the ECR repository. Defaults to the current account root (arn:aws:iam::<account_id>:root) when empty, preserving the previous behaviour. Use this to enable cross-account or cross-org pulls."
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

# ==============================================================================
# Memory (modules/memory)
# ==============================================================================

variable "create_memory" {
  description = "When true, creates an AgentCore Memory resource using modules/memory. Defaults to false."
  type        = bool
  default     = false
}

variable "memory_name" {
  description = "Name for the AgentCore Memory resource. Defaults to var.name when null."
  type        = string
  default     = null
}

variable "memory_event_expiry_duration" {
  description = "Number of days after which memory events expire (7–365). Required when create_memory = true. Defaults to 90."
  type        = number
  default     = 90

  validation {
    condition     = var.memory_event_expiry_duration >= 7 && var.memory_event_expiry_duration <= 365
    error_message = "memory_event_expiry_duration must be between 7 and 365 days."
  }
}

variable "memory_description" {
  description = "Human-readable description for the Memory resource."
  type        = string
  default     = null
}

variable "memory_encryption_key_arn" {
  description = "ARN of the KMS key used to encrypt memory data. When null, AWS-managed encryption is used."
  type        = string
  default     = null
}

variable "memory_execution_role_arn" {
  description = "ARN of the IAM role the memory service assumes. When null, the default service role is used."
  type        = string
  default     = null
}

# ==============================================================================
# Gateway (modules/gateway)
# ==============================================================================

variable "create_gateway" {
  description = "When true, creates an AgentCore Gateway resource using modules/gateway. Defaults to false."
  type        = bool
  default     = false
}

variable "gateway_name" {
  description = "Name for the AgentCore Gateway resource. Defaults to var.name when null."
  type        = string
  default     = null
}

variable "gateway_description" {
  description = "Human-readable description for the Gateway resource."
  type        = string
  default     = null
}

variable "gateway_create_role" {
  description = "When true, the gateway module creates an IAM role. Set to false and supply gateway_role_arn to reuse an existing role."
  type        = bool
  default     = true
}

variable "gateway_role_arn" {
  description = "ARN of an existing IAM role for the gateway. Required when gateway_create_role = false."
  type        = string
  default     = null
}

variable "gateway_authorizer_type" {
  description = "Gateway request authorizer type. \"CUSTOM_JWT\" requires gateway_authorizer_configuration. \"AWS_IAM\" uses SigV4."
  type        = string
  default     = "AWS_IAM"

  validation {
    condition     = contains(["CUSTOM_JWT", "AWS_IAM"], var.gateway_authorizer_type)
    error_message = "gateway_authorizer_type must be either \"CUSTOM_JWT\" or \"AWS_IAM\"."
  }
}

variable "gateway_authorizer_configuration" {
  description = "JWT authorizer configuration. Required when gateway_authorizer_type = \"CUSTOM_JWT\". Shape: { discovery_url, allowed_audience, allowed_clients }."
  type = object({
    discovery_url    = string
    allowed_audience = optional(list(string), [])
    allowed_clients  = optional(list(string), [])
  })
  default = null
}

variable "gateway_protocol_type" {
  description = "Protocol type for the gateway. Currently only \"MCP\" is supported."
  type        = string
  default     = "MCP"
}

variable "gateway_protocol_configuration" {
  description = "MCP protocol configuration. Shape: { instructions, search_type, supported_versions }."
  type = object({
    instructions       = optional(string)
    search_type        = optional(string)
    supported_versions = optional(list(string), [])
  })
  default = null
}

variable "gateway_interceptor_configurations" {
  description = "List of interceptor configurations (max 2). Each: { interception_points, lambda_arn, pass_request_headers }."
  type = list(object({
    interception_points  = list(string)
    lambda_arn           = string
    pass_request_headers = optional(bool, false)
  }))
  default = []
}

variable "gateway_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt gateway data. When null, AWS-managed encryption is used."
  type        = string
  default     = null
}

variable "gateway_exception_level" {
  description = "Exception detail level exposed via the gateway. Valid values: INFO, WARN, ERROR."
  type        = string
  default     = null

  validation {
    condition     = var.gateway_exception_level == null || contains(["INFO", "WARN", "ERROR"], var.gateway_exception_level)
    error_message = "gateway_exception_level must be one of INFO, WARN, or ERROR."
  }
}
