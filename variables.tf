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
  description = "Network mode for the AgentCore runtime. PUBLIC exposes the runtime endpoint publicly; VPC keeps traffic within your VPC via network_mode_config."
  type        = string
  default     = "PUBLIC"

  validation {
    condition     = contains(["PUBLIC", "VPC"], var.network_mode)
    error_message = "network_mode must be either \"PUBLIC\" or \"VPC\"."
  }
}

variable "vpc_security_group_ids" {
  description = "Security group IDs attached to the runtime when network_mode = \"VPC\". Must be in the same VPC as vpc_subnet_ids."
  type        = list(string)
  default     = []
}

variable "vpc_subnet_ids" {
  description = "Subnet IDs where the runtime is placed when network_mode = \"VPC\". Use private subnets for least-privilege network design."
  type        = list(string)
  default     = []
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
  description = "Full container image URI (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-agent:v1.2.3) to deploy to the runtime. Required when create_runtime = true and create_build_pipeline = false. Must be null when create_build_pipeline = true."
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
  description = "Additional environment variables injected into the AgentCore runtime process. AWS_REGION and AWS_DEFAULT_REGION are always set; BEDROCK_AGENTCORE_CODE_INTERPRETER_ID is also set when create_code_interpreter = true."
  type        = map(string)
  default     = {}
}

variable "runtime_metadata_configuration" {
  description = "AgentCore Runtime microVM metadata configuration. require_mmdsv2 maps to metadataConfiguration.requireMMDSV2. Until the AWS provider exposes this field, the runtime submodule applies it with UpdateAgentRuntime through the AWS CLI. Set to null only to disable the compatibility update."
  type = object({
    require_mmdsv2 = bool
  })
  default = {
    require_mmdsv2 = true
  }
}

# ==============================================================================
# Runtime — Authorizer
# ==============================================================================

variable "authorizer_discovery_url" {
  description = "OIDC discovery URL for JWT authorisation on the runtime endpoint (must end with /.well-known/openid-configuration). When null, the endpoint is unauthenticated at the AgentCore layer."
  type        = string
  default     = null
}

variable "authorizer_allowed_audience" {
  description = "Set of allowed JWT audience values. Ignored when authorizer_discovery_url is null."
  type        = list(string)
  default     = []
}

variable "authorizer_allowed_clients" {
  description = "Set of allowed client IDs for JWT token validation. Ignored when authorizer_discovery_url is null."
  type        = list(string)
  default     = []
}

# ==============================================================================
# Runtime — Lifecycle
# ==============================================================================

variable "idle_runtime_session_timeout" {
  description = "Idle session timeout in seconds for the runtime. When null, the service default applies."
  type        = number
  default     = null
}

variable "max_lifetime" {
  description = "Maximum instance lifetime in seconds for the runtime. When null, the service default applies."
  type        = number
  default     = null
}

# ==============================================================================
# Runtime — Protocol and Headers
# ==============================================================================

variable "server_protocol" {
  description = "Server protocol for the runtime. Valid values: HTTP, MCP, A2A. When null, the service default (HTTP) applies."
  type        = string
  default     = null

  validation {
    condition     = var.server_protocol == null ? true : contains(["HTTP", "MCP", "A2A"], var.server_protocol)
    error_message = "server_protocol must be one of: HTTP, MCP, A2A."
  }
}

variable "request_header_allowlist" {
  description = "List of HTTP request headers to pass through to the runtime container. When empty, no additional headers are forwarded."
  type        = list(string)
  default     = []
}

# ==============================================================================
# Code Interpreter
# ==============================================================================

variable "create_code_interpreter" {
  description = "When true, creates an AgentCore Code Interpreter alongside the runtime."
  type        = bool
  default     = false
}

variable "code_interpreter_name" {
  description = "Name for the AgentCore Code Interpreter. Defaults to var.name. Hyphens are automatically converted to underscores."
  type        = string
  default     = null

  validation {
    condition     = var.code_interpreter_name == null || can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,47}$", var.code_interpreter_name))
    error_message = "code_interpreter_name must start with a letter, be at most 48 characters, and contain only letters, numbers, hyphens, or underscores."
  }
}

variable "code_interpreter_description" {
  description = "Human-readable description for the AgentCore Code Interpreter."
  type        = string
  default     = "Managed by terraform-aws-agentcore."
}

variable "code_interpreter_execution_role_arn" {
  description = "ARN of an IAM role for the Code Interpreter to assume. Defaults to the runtime execution role managed or supplied through execution_role_arn."
  type        = string
  default     = null
}

variable "code_interpreter_network_mode" {
  description = "Network mode for the Code Interpreter. SANDBOX allows limited AWS service access, PUBLIC allows internet access, and VPC uses the supplied VPC configuration."
  type        = string
  default     = "SANDBOX"

  validation {
    condition     = contains(["PUBLIC", "SANDBOX", "VPC"], var.code_interpreter_network_mode)
    error_message = "code_interpreter_network_mode must be one of: PUBLIC, SANDBOX, VPC."
  }
}

variable "code_interpreter_vpc_security_group_ids" {
  description = "Security group IDs attached to the Code Interpreter when code_interpreter_network_mode = \"VPC\"."
  type        = list(string)
  default     = []
}

variable "code_interpreter_vpc_subnet_ids" {
  description = "Subnet IDs where the Code Interpreter is placed when code_interpreter_network_mode = \"VPC\"."
  type        = list(string)
  default     = []
}

# ==============================================================================
# IAM — Execution Role
# ==============================================================================

variable "create_execution_role" {
  description = "When true, the module creates an IAM execution role for AgentCore Runtime and, by default, Code Interpreter. Set to false to provide an existing role via execution_role_arn."
  type        = bool
  default     = true
}

variable "execution_role_arn" {
  description = "ARN of an existing IAM role to use as the AgentCore runtime execution role. Required when create_runtime = true and create_execution_role = false."
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

variable "additional_iam_policy_arns" {
  description = "Additional managed IAM policy ARNs to attach to the module-created execution role. Ignored when create_execution_role = false."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.additional_iam_policy_arns : can(regex("^arn:[^:]+:iam::(aws|[0-9]{12}):policy/.+$", arn))])
    error_message = "Each entry in additional_iam_policy_arns must be a valid managed IAM policy ARN."
  }
}

variable "allow_bedrock_invoke_all" {
  description = "When true (default), the inline execution role policy includes bedrock:InvokeModel and bedrock:InvokeModelWithResponseStream on Resource \"*\". Set to false to remove this broad statement and supply model-specific permissions via additional_iam_statements (recommended for production)."
  type        = bool
  default     = true
}

variable "allow_workload_access_token_for_user_id" {
  description = "When true (default), allows bedrock-agentcore:GetWorkloadAccessTokenForUserId. When false, removes it from the baseline Allow and adds an explicit Deny so broad managed policies such as BedrockAgentCoreFullAccess cannot re-enable it."
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

variable "gateway_role_policy_arns" {
  description = "Managed policy ARNs to attach to the module-created Gateway role."
  type        = set(string)
  default     = []
}

variable "gateway_role_policy_statements" {
  description = "Additional least-privilege IAM statements for the module-created Gateway role."
  type = list(object({
    sid       = optional(string)
    effect    = optional(string, "Allow")
    actions   = set(string)
    resources = set(string)
    condition = optional(any)
  }))
  default = []
}

variable "gateway_authorizer_type" {
  description = "Gateway inbound authorizer: CUSTOM_JWT, AWS_IAM, AUTHENTICATE_ONLY, or NONE."
  type        = string
  default     = "AWS_IAM"

  validation {
    condition     = contains(["CUSTOM_JWT", "AWS_IAM", "AUTHENTICATE_ONLY", "NONE"], var.gateway_authorizer_type)
    error_message = "gateway_authorizer_type must be CUSTOM_JWT, AWS_IAM, AUTHENTICATE_ONLY, or NONE."
  }
}

variable "gateway_authorizer_configuration" {
  description = "Advanced JWT authorizer configuration. Required only when gateway_authorizer_type is CUSTOM_JWT."
  type = object({
    discovery_url            = string
    allowed_audience         = optional(set(string), [])
    allowed_clients          = optional(set(string), [])
    allowed_scopes           = optional(set(string), [])
    workload_identities      = optional(list(string), [])
    hosting_environment_arns = optional(list(string), [])
    custom_claims = optional(set(object({
      inbound_token_claim_name       = string
      inbound_token_claim_value_type = string
      claim_match_operator           = string
      match_value_string             = optional(string)
      match_value_string_list        = optional(set(string))
    })), [])
    private_endpoint = optional(object({
      managed_vpc_resource = optional(object({
        endpoint_ip_address_type = string
        subnet_ids               = set(string)
        vpc_identifier           = string
        routing_domain           = optional(string)
        security_group_ids       = optional(set(string), [])
        tags                     = optional(map(string), {})
      }))
      self_managed_lattice_resource = optional(object({
        resource_configuration_identifier = string
      }))
    }))
    private_endpoint_overrides = optional(list(object({
      domain = string
      private_endpoint = object({
        managed_vpc_resource = optional(object({
          endpoint_ip_address_type = string
          subnet_ids               = set(string)
          vpc_identifier           = string
          routing_domain           = optional(string)
          security_group_ids       = optional(set(string), [])
          tags                     = optional(map(string), {})
        }))
        self_managed_lattice_resource = optional(object({
          resource_configuration_identifier = string
        }))
      })
    })), [])
  })
  default = null

  validation {
    condition = var.gateway_authorizer_configuration == null || alltrue([
      for claim in var.gateway_authorizer_configuration.custom_claims : (
        contains(["STRING", "STRING_ARRAY"], claim.inbound_token_claim_value_type) &&
        contains(["EQUALS", "CONTAINS", "CONTAINS_ANY"], claim.claim_match_operator) &&
        ((claim.match_value_string != null) != (claim.match_value_string_list != null)) &&
        (claim.claim_match_operator != "EQUALS" || claim.inbound_token_claim_value_type == "STRING") &&
        (!contains(["CONTAINS", "CONTAINS_ANY"], claim.claim_match_operator) || claim.inbound_token_claim_value_type == "STRING_ARRAY") &&
        (claim.claim_match_operator != "CONTAINS_ANY" || claim.match_value_string_list != null) &&
        (claim.claim_match_operator == "CONTAINS_ANY" || claim.match_value_string != null)
      )
    ])
    error_message = "Each Gateway JWT custom claim must use a compatible value type, operator, and exactly one match value shape."
  }
}

variable "gateway_protocol_type" {
  description = "Optional gateway aggregation protocol. Set to \"MCP\" for MCP aggregation, or null for general HTTP targets such as AgentCore Runtime agents. MCP is inferred when an MCP target is configured."
  type        = string
  default     = null

  validation {
    condition     = var.gateway_protocol_type == null ? true : var.gateway_protocol_type == "MCP"
    error_message = "gateway_protocol_type must be \"MCP\" or null."
  }
}

variable "gateway_protocol_configuration" {
  description = "Optional MCP protocol instructions, versions, session timeout, and response streaming configuration."
  type = object({
    instructions               = optional(string)
    search_type                = optional(string)
    supported_versions         = optional(set(string), [])
    session_timeout_in_seconds = optional(number)
    enable_response_streaming  = optional(bool)
  })
  default = null
}

variable "gateway_policy_engine_configuration" {
  description = "Optional Policy Engine association for the Gateway."
  type = object({
    arn  = string
    mode = string
  })
  default = null

  validation {
    condition     = var.gateway_policy_engine_configuration == null || contains(["LOG_ONLY", "ENFORCE"], var.gateway_policy_engine_configuration.mode)
    error_message = "gateway_policy_engine_configuration.mode must be LOG_ONLY or ENFORCE."
  }
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

variable "gateway_targets" {
  description = "Map of general Gateway Targets using the native target_configuration, credential, metadata, private endpoint, and timeout shapes."
  type        = any
  default     = {}

  validation {
    condition = can(keys(var.gateway_targets)) && alltrue([
      for target in values(var.gateway_targets) : try(target.name, null) == null || can(regex("^([0-9a-zA-Z][-]?){1,100}$", target.name))
    ])
    error_message = "Each gateway_targets target name must contain only letters, numbers, and hyphens, start with a letter or number, and be at most 100 characters."
  }
}

variable "gateway_runtime_invoke_arns" {
  description = "Additional AgentCore Runtime ARNs the module-created Gateway role may invoke. HTTP Runtime target ARNs are inferred automatically."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.gateway_runtime_invoke_arns : can(regex("^arn:aws[^:]*:bedrock-agentcore:[a-z0-9-]+:[0-9]{12}:(runtime|agent)/.+", arn))
    ])
    error_message = "Each gateway_runtime_invoke_arns value must be a valid Bedrock AgentCore Runtime ARN."
  }
}

variable "gateway_attach_runtime_target" {
  description = "When true, attach the runtime created by this module call as a Gateway Target under the reserved key runtime. HTTP or MCP is inferred from the Gateway and Runtime protocols."
  type        = bool
  default     = false
}

variable "gateway_runtime_target" {
  description = "Configuration for the module-created Runtime target when gateway_attach_runtime_target is true."
  type = object({
    name                              = optional(string)
    description                       = optional(string)
    region                            = optional(string)
    qualifier                         = optional(string, "DEFAULT")
    credential_provider_configuration = optional(any, { gateway_iam_role = { service = "bedrock-agentcore" } })
    metadata_configuration = optional(object({
      allowed_query_parameters = optional(set(string), [])
      allowed_request_headers  = optional(set(string), [])
      allowed_response_headers = optional(set(string), [])
    }))
    private_endpoint = optional(any)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.gateway_runtime_target.name == null || can(regex("^([0-9a-zA-Z][-]?){1,100}$", var.gateway_runtime_target.name))
    error_message = "gateway_runtime_target.name must contain only letters, numbers, and hyphens, start with a letter or number, and be at most 100 characters."
  }
}

variable "gateway_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt gateway data. When null, AWS-managed encryption is used."
  type        = string
  default     = null
}

variable "gateway_exception_level" {
  description = "Exception detail level exposed via the Gateway. AgentCore currently accepts only DEBUG."
  type        = string
  default     = null

  validation {
    condition     = var.gateway_exception_level == null ? true : var.gateway_exception_level == "DEBUG"
    error_message = "gateway_exception_level must be DEBUG or null."
  }
}

variable "gateway_region" {
  description = "AWS Region in which to manage the Gateway. Defaults to the provider Region."
  type        = string
  default     = null
}

variable "gateway_timeouts" {
  description = "Optional create, update, and delete timeouts for the Gateway."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
