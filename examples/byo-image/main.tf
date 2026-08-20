# ==============================================================================
# Example: Bring Your Own Image (BYO)
#
# Provisions an AgentCore runtime using a container image that you have
# already built and pushed to any accessible registry (ECR, GHCR, Docker Hub,
# etc.). No CodeBuild, S3, or ECR resources are created by this module call.
#
# Prerequisites:
#   - Your image must be accessible by the AgentCore execution role.
#     If it lives in a private ECR repo, add an ECR pull statement via
#     additional_iam_statements (see commented block below).
#   - Set build_mode = "byo" and supply the full image URI.
#
# Run:
#   tofu init
#   tofu apply -var="image_uri=<your-registry>/<your-image>:<tag>"
# ==============================================================================

module "agentcore" {
  source = "../.."
  # Uncomment once published to the registry:
  # source  = "LuisOsuna117/agentcore/aws"
  # version = "~> 2.0"

  # ---- Required ---------------------------------------------------------------
  name = var.name

  # ---- BYO image workflow -----------------------------------------------------
  create_build_pipeline = false
  image_uri             = var.image_uri

  # ---- Runtime ----------------------------------------------------------------
  description  = "BYO-image AgentCore runtime example."
  network_mode = "PUBLIC"

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  # ---- IAM --------------------------------------------------------------------
  attach_bedrock_fullaccess_policy = true

  # If your image lives in a private ECR repository in the same account,
  # grant the execution role permission to pull it:
  # additional_iam_statements = [
  #   {
  #     Sid    = "ECRImagePull"
  #     Effect = "Allow"
  #     Action = [
  #       "ecr:BatchGetImage",
  #       "ecr:GetDownloadUrlForLayer",
  #       "ecr:BatchCheckLayerAvailability",
  #     ]
  #     Resource = "arn:aws:ecr:us-east-1:123456789012:repository/my-agent"
  #   },
  # ]

  # ---- Tags -------------------------------------------------------------------
  tags = {
    Environment = "example"
    Workflow    = "byo"
  }
}
