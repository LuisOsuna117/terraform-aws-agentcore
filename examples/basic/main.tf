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
  # Uncomment once published to the registry:
  # source  = "LuisOsuna117/agentcore/aws"
  # version = "~> 1.0"

  # ---- Required ---------------------------------------------------------------
  name = var.name

  # ---- Source code ------------------------------------------------------------
  # Points to the agent-code/ directory bundled with this example.
  # In your own project use: agent_source_dir = "${path.root}/src/my-agent"
  agent_source_dir = "${path.module}/agent-code"

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
  # The module creates an execution role by default with a lean inline policy.
  # BedrockAgentCoreFullAccess is attached for convenience in this example.
  # For production, set attach_bedrock_fullaccess_policy = false and use
  # additional_iam_statements to grant only what your agent needs.
  attach_bedrock_fullaccess_policy = true

  # Example: grant access to a specific Claude model only.
  # additional_iam_statements = [
  #   {
  #     Sid    = "ClaudeAccess"
  #     Effect = "Allow"
  #     Action = [
  #       "bedrock:InvokeModel",
  #       "bedrock:InvokeModelWithResponseStream",
  #     ]
  #     Resource = "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0"
  #   },
  # ]

  # ---- ECR --------------------------------------------------------------------
  ecr_scan_on_push         = true
  ecr_lifecycle_keep_count = 10

  # ---- Tags -------------------------------------------------------------------
  tags = {
    Environment = "example"
  }
}
