# ==============================================================================
# Example: CodeBuild Workflow — Trigger Disabled
#
# Provisions the full CodeBuild infrastructure (ECR + S3 + CodeBuild project)
# but does NOT automatically start a build on terraform apply.
# The build must be triggered manually or by your own CI/CD pipeline.
#
# Use this pattern when:
#   - You want Terraform to own the build infra but prefer to drive builds
#     from GitHub Actions, GitLab CI, or another pipeline tool.
#   - You are in a restricted environment where the Terraform executor does
#     not have AWS CLI or internet access.
#   - You want to decouple infra changes from image rebuilds.
#
# After apply, trigger a build manually:
#   aws codebuild start-build --project-name <codebuild_project_name>
#
# Or use the provided script directly:
#   scripts/build-image.sh <project> <region> <repo-name> <tag> <repo-url>
#
# Run:
#   tofu init
#   tofu apply
# ==============================================================================

module "agentcore" {
  source = "../.."
  # Uncomment once published to the registry:
  # source  = "LuisOsuna117/agentcore/aws"
  # version = "~> 2.0"

  # ---- Required ---------------------------------------------------------------
  name = var.name

  # ---- Build workflow ---------------------------------------------------------
  create_build_pipeline  = true
  trigger_build_on_apply = false # <-- builds are NOT triggered automatically

  agent_source_dir = "${path.module}/../basic/agent-code"

  # ---- Runtime ----------------------------------------------------------------
  description  = "CodeBuild workflow — trigger disabled."
  network_mode = "PUBLIC"
  image_tag    = "latest"

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  # ---- IAM --------------------------------------------------------------------
  attach_bedrock_fullaccess_policy = true

  # ---- Tags -------------------------------------------------------------------
  tags = {
    Environment = "example"
    Workflow    = "codebuild-no-trigger"
  }
}
