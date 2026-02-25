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
}

# ==============================================================================
# AgentCore Runtime
# ==============================================================================

resource "aws_bedrockagentcore_agent_runtime" "this" {
  agent_runtime_name = local.runtime_name
  description        = var.description
  role_arn           = local.execution_role_arn

  agent_runtime_artifact {
    container_configuration {
      container_uri = "${aws_ecr_repository.this.repository_url}:${var.image_tag}"
    }
  }

  network_configuration {
    network_mode = var.network_mode
  }

  # AWS_REGION and AWS_DEFAULT_REGION are injected automatically using the
  # current region from the AWS provider. Callers can append additional
  # variables via var.environment_variables.
  environment_variables = merge(
    {
      AWS_REGION         = data.aws_region.current.id
      AWS_DEFAULT_REGION = data.aws_region.current.id
    },
    var.environment_variables,
  )

  depends_on = [
    null_resource.trigger_build,
    aws_iam_role_policy.agent_execution,
    aws_iam_role_policy_attachment.agent_execution_managed,
  ]
}
