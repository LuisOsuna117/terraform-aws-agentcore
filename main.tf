# ==============================================================================
# Locals — Naming, Tagging, and Derived Values
# ==============================================================================

locals {
  # Normalise the runtime name: AgentCore requires underscores, not hyphens.
  runtime_name = replace(coalesce(var.runtime_name, var.name), "-", "_")

  # ECR repository name falls back to var.name if not explicitly set.
  ecr_repository_name = coalesce(var.ecr_repository_name, var.name)

  # Agent source directory — allows callers to supply their own path.
  agent_source_dir = coalesce(var.agent_source_dir, "${path.module}/agent-code")

  # Execution role ARN — from the module-created role or the caller-supplied one.
  execution_role_arn = var.create_execution_role ? aws_iam_role.agent_execution[0].arn : var.execution_role_arn

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
}

# ==============================================================================
# Cross-variable Validations
# (terraform_data is a built-in resource — no external provider required)
# ==============================================================================

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = !(!var.create_build_pipeline && (var.image_uri == null || trimspace(var.image_uri) == ""))
      error_message = "image_uri must be set and non-empty when create_build_pipeline = false."
    }

    precondition {
      condition     = !(var.create_build_pipeline && var.image_uri != null)
      error_message = "image_uri must be null when create_build_pipeline = true. Use image_tag to control the built image tag."
    }

    precondition {
      condition     = !(var.trigger_build_on_apply && !var.create_build_pipeline)
      error_message = "trigger_build_on_apply = true has no effect when create_build_pipeline = false. Set it to false."
    }

    precondition {
      condition     = var.create_execution_role || var.execution_role_arn != null
      error_message = "execution_role_arn must be provided when create_execution_role = false."
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

  # AWS_REGION and AWS_DEFAULT_REGION are injected automatically.
  # Callers can append additional variables via var.environment_variables.
  environment_variables = merge(
    {
      AWS_REGION         = data.aws_region.current.id
      AWS_DEFAULT_REGION = data.aws_region.current.id
    },
    var.environment_variables,
  )

  depends_on = [
    terraform_data.validations,
    module.build,
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
