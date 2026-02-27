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
