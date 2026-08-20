# ==============================================================================
# Example: Basic AgentCore Runtime
#
# Provisions a single AgentCore runtime with:
#   - An ECR repository for the agent container image
#   - A CodeBuild project that builds and pushes the image automatically
#   - A least-privilege IAM execution role
#   - A private, versioned S3 bucket for agent source code
#
# Place your agent application code (including a Dockerfile) in the
# agent-code/ directory next to this file, then run:
#
#   tofu init
#   tofu apply
# ==============================================================================

module "agentcore" {
  source = "../.."

  # ---- Required ---------------------------------------------------------------
  name = var.name

  # Every feature is opt-in. The default source path resolves to the
  # agent-code/ directory in this root configuration.
  create_build_pipeline  = true
  trigger_build_on_apply = true
  create_runtime         = true
  create_execution_role  = true

  # ---- Runtime ----------------------------------------------------------------
  description  = "Basic AgentCore runtime example."
  network_mode = "PUBLIC"
  image_tag    = "latest"

  # Optional environment variables injected into the running agent process.
  # AWS_REGION and AWS_DEFAULT_REGION are set automatically.
  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  # ---- IAM --------------------------------------------------------------------
  # The execution role starts with the service baseline only. Add
  # model-specific statements required by your agent; broad managed policies
  # and wildcard model invocation remain disabled.

  # ---- ECR --------------------------------------------------------------------
  ecr_scan_on_push         = true
  ecr_lifecycle_keep_count = 10

  # ---- Tags -------------------------------------------------------------------
  tags = {
    Environment = "example"
  }
}
