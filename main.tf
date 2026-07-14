# ==============================================================================
# Locals — Naming, Tagging, and Derived Values
# ==============================================================================

locals {
  # Normalise the runtime name: AgentCore requires underscores, not hyphens.
  runtime_name = replace(coalesce(var.runtime_name, var.name), "-", "_")

  # Code Interpreter follows the same naming constraint as Runtime.
  code_interpreter_name = replace(coalesce(var.code_interpreter_name, var.name), "-", "_")

  # ECR repository name falls back to var.name if not explicitly set.
  ecr_repository_name = coalesce(var.ecr_repository_name, var.name)

  # Agent source directory — allows callers to supply their own path.
  agent_source_dir = coalesce(var.agent_source_dir, "${path.module}/agent-code")

  # Execution role ARN — from the module-created role or the caller-supplied one.
  execution_role_arn = var.create_execution_role ? aws_iam_role.agent_execution[0].arn : var.execution_role_arn

  # Reuse the runtime execution role by default, while allowing a dedicated
  # Code Interpreter execution role for least-privilege deployments.
  code_interpreter_execution_role_arn = var.code_interpreter_execution_role_arn != null ? var.code_interpreter_execution_role_arn : local.execution_role_arn

  # Tags applied to every taggable resource.
  common_tags = merge(
    {
      Module    = "terraform-aws-agentcore"
      ManagedBy = "Terraform"
    },
    var.tags,
  )

  # The container image URI used by the runtime.
  # create_build_pipeline = true  → ECR repo URL + image_tag from module.build
  # create_build_pipeline = false → caller-supplied image_uri (BYO)
  effective_image_uri = var.create_build_pipeline ? module.build[0].image_uri : var.image_uri

  # Optional self-target: attach the runtime created by this root module call to
  # the gateway created by this same call. The stable map key is "runtime".
  gateway_runtime_target_key  = "runtime"
  gateway_runtime_target_name = coalesce(var.gateway_runtime_target.name, local.gateway_runtime_target_key)
  gateway_has_mcp_targets = length(var.gateway_mcp_targets) > 0 || anytrue([
    for target in values(var.gateway_targets) : upper(target.target_type) == "MCP"
  ])
  gateway_has_agent_targets = anytrue([
    for target in values(var.gateway_targets) : upper(target.target_type) == "AGENT"
  ])
  gateway_runtime_target_type = coalesce(
    try(upper(var.gateway_runtime_target.target_type), null),
    var.gateway_protocol_type == "MCP" || local.gateway_has_mcp_targets ? "MCP" : (
      local.gateway_has_agent_targets ? "AGENT" : (var.server_protocol == "MCP" ? "MCP" : "AGENT")
    ),
  )

  gateway_runtime_target = var.gateway_attach_runtime_target && var.create_runtime ? {
    (local.gateway_runtime_target_key) = {
      target_type              = local.gateway_runtime_target_type
      name                     = local.gateway_runtime_target_name
      description              = var.gateway_runtime_target.description
      endpoint                 = null
      agent_runtime_arn        = module.runtime[0].agent_runtime_arn
      qualifier                = coalesce(var.gateway_runtime_target.qualifier, "DEFAULT")
      schema                   = var.gateway_runtime_target.schema
      allowed_query_parameters = var.gateway_runtime_target.allowed_query_parameters
      allowed_request_headers  = var.gateway_runtime_target.allowed_request_headers
      allowed_response_headers = var.gateway_runtime_target.allowed_response_headers
    }
  } : {}

  effective_gateway_targets = merge(
    var.gateway_targets,
    local.gateway_runtime_target,
  )

  gateway_agent_runtime_target_keys = setunion(
    toset([
      for key, target in var.gateway_mcp_targets : key
      if try(trimspace(target.endpoint), "") == ""
    ]),
    toset([
      for key, target in var.gateway_targets : key
      if upper(target.target_type) == "MCP" && try(trimspace(target.endpoint), "") == ""
    ]),
    var.gateway_attach_runtime_target && var.create_runtime && local.gateway_runtime_target_type == "MCP" ? toset([local.gateway_runtime_target_key]) : toset([]),
  )

  gateway_target_names = concat(
    [for key, target in var.gateway_mcp_targets : coalesce(target.name, key)],
    [for key, target in var.gateway_targets : coalesce(target.name, key)],
  )
}

# ==============================================================================
# Cross-variable Validations
# (terraform_data is a built-in resource — no external provider required)
# ==============================================================================

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = !(!var.create_build_pipeline && var.create_runtime && (var.image_uri == null || trimspace(var.image_uri) == ""))
      error_message = "image_uri must be set and non-empty when create_runtime = true and create_build_pipeline = false."
    }

    precondition {
      condition     = !(var.create_build_pipeline && var.image_uri != null)
      error_message = "image_uri must be null when create_build_pipeline = true. Use image_tag to control the built image tag."
    }

    precondition {
      condition     = var.create_execution_role || !var.create_runtime || var.execution_role_arn != null
      error_message = "execution_role_arn must be provided when create_runtime = true and create_execution_role = false."
    }

    precondition {
      condition     = !(var.network_mode == "VPC" && (length(var.vpc_security_group_ids) == 0 || length(var.vpc_subnet_ids) == 0))
      error_message = "vpc_security_group_ids and vpc_subnet_ids must both be non-empty when network_mode = \"VPC\"."
    }

    precondition {
      condition     = !var.create_code_interpreter || var.code_interpreter_network_mode != "SANDBOX" || local.code_interpreter_execution_role_arn != null
      error_message = "A Code Interpreter execution role is required in SANDBOX mode. Enable create_execution_role, set execution_role_arn, or set code_interpreter_execution_role_arn."
    }

    precondition {
      condition     = !var.create_code_interpreter || var.code_interpreter_network_mode != "VPC" || (length(var.code_interpreter_vpc_security_group_ids) > 0 && length(var.code_interpreter_vpc_subnet_ids) > 0)
      error_message = "code_interpreter_vpc_security_group_ids and code_interpreter_vpc_subnet_ids must both be non-empty when code_interpreter_network_mode = \"VPC\"."
    }

    precondition {
      condition     = var.create_gateway || (length(var.gateway_targets) == 0 && length(var.gateway_mcp_targets) == 0)
      error_message = "gateway_targets and gateway_mcp_targets require create_gateway = true."
    }

    precondition {
      condition     = !var.gateway_attach_runtime_target || var.create_runtime
      error_message = "gateway_attach_runtime_target = true requires create_runtime = true."
    }

    precondition {
      condition     = !var.gateway_attach_runtime_target || var.create_gateway
      error_message = "gateway_attach_runtime_target = true requires create_gateway = true."
    }

    precondition {
      condition     = !var.gateway_attach_runtime_target || (!contains(keys(var.gateway_targets), local.gateway_runtime_target_key) && !contains(keys(var.gateway_mcp_targets), local.gateway_runtime_target_key))
      error_message = "gateway_targets and gateway_mcp_targets cannot use key \"runtime\" when gateway_attach_runtime_target = true; that key is reserved for the module-created runtime target."
    }

    precondition {
      condition     = !var.gateway_attach_runtime_target || !contains(local.gateway_target_names, local.gateway_runtime_target_name)
      error_message = "gateway_runtime_target.name must not collide with any resolved gateway target name."
    }

    precondition {
      condition     = length(setintersection(toset(keys(var.gateway_targets)), toset(keys(var.gateway_mcp_targets)))) == 0
      error_message = "gateway_targets and gateway_mcp_targets must not use the same map key."
    }

    precondition {
      condition     = var.gateway_runtime_target.schema == null || local.gateway_runtime_target_type == "AGENT"
      error_message = "gateway_runtime_target.schema is only supported when the effective target type is AGENT."
    }
  }
}

# ==============================================================================
# Build Submodule (codebuild mode only)
#
# Provisions ECR, S3, CodeBuild, IAM for the build pipeline, and optionally
# triggers a build on apply. Not created when build_mode = "byo".
# ==============================================================================

module "build" {
  count  = var.create_build_pipeline ? 1 : 0
  source = "./modules/build"

  name                = var.name
  common_tags         = local.common_tags
  ecr_repository_name = local.ecr_repository_name

  # ECR
  ecr_image_tag_mutability = var.ecr_image_tag_mutability
  ecr_scan_on_push         = var.ecr_scan_on_push
  ecr_lifecycle_keep_count = var.ecr_lifecycle_keep_count
  ecr_force_delete         = var.ecr_force_delete
  ecr_pull_principals      = var.ecr_pull_principals

  # S3
  agent_source_dir            = local.agent_source_dir
  source_bucket_force_destroy = var.source_bucket_force_destroy

  # CodeBuild
  image_tag                   = var.image_tag
  codebuild_compute_type      = var.codebuild_compute_type
  codebuild_environment_image = var.codebuild_environment_image
  codebuild_environment_type  = var.codebuild_environment_type
  codebuild_build_timeout     = var.codebuild_build_timeout
  trigger_build_on_apply      = var.trigger_build_on_apply

  depends_on = [terraform_data.validations]
}

# ==============================================================================
# Runtime Submodule
# ==============================================================================

module "runtime" {
  count  = var.create_runtime ? 1 : 0
  source = "./modules/runtime"

  runtime_name       = local.runtime_name
  description        = var.description
  execution_role_arn = local.execution_role_arn
  image_uri          = local.effective_image_uri
  network_mode       = var.network_mode

  # VPC networking (only used when network_mode = "VPC")
  vpc_security_group_ids = var.vpc_security_group_ids
  vpc_subnet_ids         = var.vpc_subnet_ids

  # JWT authorizer (optional)
  authorizer_discovery_url    = var.authorizer_discovery_url
  authorizer_allowed_audience = var.authorizer_allowed_audience
  authorizer_allowed_clients  = var.authorizer_allowed_clients

  # Lifecycle (optional)
  idle_runtime_session_timeout = var.idle_runtime_session_timeout
  max_lifetime                 = var.max_lifetime

  # Protocol and headers (optional)
  server_protocol          = var.server_protocol
  request_header_allowlist = var.request_header_allowlist

  # AWS_REGION and AWS_DEFAULT_REGION are injected automatically.
  # Callers can append additional variables via var.environment_variables.
  environment_variables = merge(
    {
      AWS_REGION         = data.aws_region.current.id
      AWS_DEFAULT_REGION = data.aws_region.current.id
    },
    var.create_code_interpreter ? {
      # Module-defined convention: agent code can read this value to start and
      # invoke sessions without hard-coding the generated resource identifier.
      BEDROCK_AGENTCORE_CODE_INTERPRETER_ID = module.code_interpreter[0].code_interpreter_id
    } : {},
    var.environment_variables,
  )

  depends_on = [
    terraform_data.validations,
    module.build,
    aws_iam_role_policy.agent_execution,
    aws_iam_role_policy.code_interpreter_invoke,
    aws_iam_role_policy_attachment.agent_execution_managed,
  ]
}

# ==============================================================================
# Code Interpreter Submodule
# ==============================================================================

module "code_interpreter" {
  count  = var.create_code_interpreter ? 1 : 0
  source = "./modules/code-interpreter"

  name               = local.code_interpreter_name
  description        = var.code_interpreter_description
  execution_role_arn = local.code_interpreter_execution_role_arn
  network_mode       = var.code_interpreter_network_mode

  vpc_security_group_ids = var.code_interpreter_vpc_security_group_ids
  vpc_subnet_ids         = var.code_interpreter_vpc_subnet_ids
  tags                   = local.common_tags

  depends_on = [
    terraform_data.validations,
    aws_iam_role_policy.agent_execution,
    aws_iam_role_policy_attachment.agent_execution_managed,
  ]
}

# ==============================================================================
# Memory Submodule
# ==============================================================================

module "memory" {
  count  = var.create_memory ? 1 : 0
  source = "./modules/memory"

  name                      = coalesce(var.memory_name, var.name)
  event_expiry_duration     = var.memory_event_expiry_duration
  description               = var.memory_description
  encryption_key_arn        = var.memory_encryption_key_arn
  memory_execution_role_arn = var.memory_execution_role_arn
  tags                      = local.common_tags
}

# ==============================================================================
# Gateway Submodule
# ==============================================================================

module "gateway" {
  count  = var.create_gateway ? 1 : 0
  source = "./modules/gateway"

  name                       = coalesce(var.gateway_name, var.name)
  description                = var.gateway_description
  create_role                = var.gateway_create_role
  role_arn                   = var.gateway_role_arn
  authorizer_type            = var.gateway_authorizer_type
  authorizer_configuration   = var.gateway_authorizer_configuration
  protocol_type              = var.gateway_protocol_type
  protocol_configuration     = var.gateway_protocol_configuration
  interceptor_configurations = var.gateway_interceptor_configurations
  targets                    = local.effective_gateway_targets
  mcp_targets                = var.gateway_mcp_targets
  agent_runtime_target_keys  = local.gateway_agent_runtime_target_keys
  kms_key_arn                = var.gateway_kms_key_arn
  exception_level            = var.gateway_exception_level
  tags                       = local.common_tags
}

# ==============================================================================
# Data Sources
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# AgentCore Execution Role
#
# Set create_execution_role = false and supply execution_role_arn to reuse an
# existing role instead of creating one.
# ==============================================================================

resource "aws_iam_role" "agent_execution" {
  count = var.create_execution_role ? 1 : 0

  name = "${var.name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AgentCoreAssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "bedrock-agentcore.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:aws:bedrock-agentcore:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:*"
        }
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${var.name}-execution-role"
  })
}

# AWS-managed policy — provides broad AgentCore permissions out of the box.
# Set attach_bedrock_fullaccess_policy = false to rely solely on the inline
# policy (and any additional_iam_statements you provide) for a tighter posture.
resource "aws_iam_role_policy_attachment" "agent_execution_managed" {
  count = var.create_execution_role && var.attach_bedrock_fullaccess_policy ? 1 : 0

  role       = aws_iam_role.agent_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/BedrockAgentCoreFullAccess"
}

# Inline policy — least-privilege baseline plus any caller-supplied statements.
resource "aws_iam_role_policy" "agent_execution" {
  count = var.create_execution_role ? 1 : 0

  name = "${var.name}-execution-policy"
  role = aws_iam_role.agent_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # ECR — pull the agent container image (create_build_pipeline = true only).
      # When create_build_pipeline = false, callers grant their own pull
      # permissions via additional_iam_statements if the image is in a private
      # registry.
      var.create_build_pipeline ? [
        {
          Sid    = "ECRImagePull"
          Effect = "Allow"
          Action = [
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchCheckLayerAvailability",
          ]
          Resource = module.build[0].ecr_repository_arn
        },
      ] : [],
      [
        {
          Sid      = "ECRAuthToken"
          Effect   = "Allow"
          Action   = ["ecr:GetAuthorizationToken"]
          Resource = "*"
        },
        # CloudWatch Logs — runtime stdout/stderr
        # DescribeLogGroups requires a broad log-group:* resource to function correctly.
        {
          Sid      = "CloudWatchLogsDescribeGroups"
          Effect   = "Allow"
          Action   = ["logs:DescribeLogGroups"]
          Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:*"
        },
        # CreateLogGroup/DescribeLogStreams are scoped to the agentcore log group.
        {
          Sid    = "CloudWatchLogsGroup"
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:DescribeLogStreams",
          ]
          Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*"
        },
        # CreateLogStream/PutLogEvents must target the log-stream ARN (requires :log-stream:* suffix).
        {
          Sid    = "CloudWatchLogsStream"
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*:log-stream:*"
        },
        # X-Ray — distributed tracing
        {
          Sid    = "XRayTracing"
          Effect = "Allow"
          Action = [
            "xray:PutTraceSegments",
            "xray:PutTelemetryRecords",
            "xray:GetSamplingRules",
            "xray:GetSamplingTargets",
          ]
          Resource = "*"
        },
        # CloudWatch Metrics — scoped to the agentcore namespace
        {
          Sid      = "CloudWatchMetrics"
          Effect   = "Allow"
          Action   = ["cloudwatch:PutMetricData"]
          Resource = "*"
          Condition = {
            StringEquals = {
              "cloudwatch:namespace" = "bedrock-agentcore"
            }
          }
        },
        # Bedrock model invocation — included by default.
        # Set allow_bedrock_invoke_all = false and supply scoped statements via
        # additional_iam_statements for a least-privilege production posture.
      ],
      var.allow_bedrock_invoke_all ? [
        {
          Sid    = "BedrockModelInvocation"
          Effect = "Allow"
          Action = [
            "bedrock:InvokeModel",
            "bedrock:InvokeModelWithResponseStream",
          ]
          Resource = "*"
        },
      ] : [],
      [
        {
          Sid    = "WorkloadAccessTokens"
          Effect = "Allow"
          Action = [
            "bedrock-agentcore:GetWorkloadAccessToken",
            "bedrock-agentcore:GetWorkloadAccessTokenForJWT",
            "bedrock-agentcore:GetWorkloadAccessTokenForUserId",
          ]
          Resource = [
            "arn:aws:bedrock-agentcore:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default",
            "arn:aws:bedrock-agentcore:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/*",
          ]
        },
      ],
      # Caller-supplied statements merged last so they can override defaults.
      var.additional_iam_statements,
    )
  })
}

# Runtime access to the custom Code Interpreter. This policy is separate from
# the baseline execution policy so it can target the generated custom ARN
# without creating a dependency cycle during Code Interpreter creation.
resource "aws_iam_role_policy" "code_interpreter_invoke" {
  count = var.create_execution_role && var.create_runtime && var.create_code_interpreter ? 1 : 0

  name = "${var.name}-code-interpreter-invoke"
  role = aws_iam_role.agent_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "CodeInterpreterSessions"
      Effect = "Allow"
      Action = [
        "bedrock-agentcore:GetCodeInterpreterSession",
        "bedrock-agentcore:InvokeCodeInterpreter",
        "bedrock-agentcore:ListCodeInterpreterSessions",
        "bedrock-agentcore:StartCodeInterpreterSession",
        "bedrock-agentcore:StopCodeInterpreterSession",
      ]
      Resource = module.code_interpreter[0].code_interpreter_arn
    }]
  })
}
