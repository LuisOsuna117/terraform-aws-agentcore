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
        # Bedrock model invocation
        {
          Sid    = "BedrockModelInvocation"
          Effect = "Allow"
          Action = [
            "bedrock:InvokeModel",
            "bedrock:InvokeModelWithResponseStream",
          ]
          Resource = "*"
        },
        # Workload access tokens (agent-to-agent identity)
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
