# ==============================================================================
# Data Sources
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # When the caller supplies no explicit pull principals, default to the current
  # account root — identical to the previous hardcoded behaviour.
  effective_ecr_pull_principals = length(var.ecr_pull_principals) > 0 ? var.ecr_pull_principals : [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
  ]
}

# ==============================================================================
# ECR Repository — Agent Container Registry
# ==============================================================================

resource "aws_ecr_repository" "this" {
  name                 = var.ecr_repository_name
  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  force_delete = var.ecr_force_delete

  tags = merge(var.common_tags, {
    Name = var.ecr_repository_name
  })
}

# Repository policy — allow the configured principals to pull images.
resource "aws_ecr_repository_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowPull"
      Effect = "Allow"
      Principal = {
        AWS = local.effective_ecr_pull_principals
      }
      Action = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]
    }]
  })
}

# Lifecycle policy — retain the N most-recent images; expire older ones.
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Retain the ${var.ecr_lifecycle_keep_count} most recent images."
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.ecr_lifecycle_keep_count
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ==============================================================================
# S3 Bucket — Agent Source Code
# ==============================================================================

resource "aws_s3_bucket" "agent_source" {
  bucket_prefix = "${var.name}-agent-source-"
  force_destroy = var.source_bucket_force_destroy

  tags = merge(var.common_tags, {
    Name    = "${var.name}-agent-source"
    Purpose = "Agent source code for CodeBuild"
  })
}

resource "aws_s3_bucket_public_access_block" "agent_source" {
  bucket = aws_s3_bucket.agent_source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "agent_source" {
  bucket = aws_s3_bucket.agent_source.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "agent_source" {
  bucket = aws_s3_bucket.agent_source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# The entire agent-code directory is zipped; MD5 is embedded in the S3 key so
# CodeBuild is re-triggered whenever the source changes.
data "archive_file" "agent_source" {
  type        = "zip"
  source_dir  = var.agent_source_dir
  output_path = "${path.module}/.terraform/agent-source.zip"
}

resource "aws_s3_object" "agent_source" {
  bucket = aws_s3_bucket.agent_source.id
  key    = "agent-source-${data.archive_file.agent_source.output_md5}.zip"
  source = data.archive_file.agent_source.output_path
  etag   = data.archive_file.agent_source.output_md5

  tags = merge(var.common_tags, {
    Name       = "agent-source"
    ArchiveMD5 = data.archive_file.agent_source.output_md5
  })
}

# ==============================================================================
# IAM — CodeBuild Service Role
# ==============================================================================

resource "aws_iam_role" "image_build" {
  name = "${var.name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "CodeBuildAssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, {
    Name = "${var.name}-codebuild-role"
  })
}

resource "aws_iam_role_policy" "image_build" {
  name = "${var.name}-codebuild-policy"
  role = aws_iam_role.image_build.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logs — build logs
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"
      },
      # ECR — push built image
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
        ]
        Resource = aws_ecr_repository.this.arn
      },
      {
        Sid      = "ECRAuthToken"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      # S3 — read agent source code archive
      {
        Sid    = "S3GetSource"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
        ]
        Resource = "${aws_s3_bucket.agent_source.arn}/*"
      },
      {
        Sid    = "S3ListSource"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = aws_s3_bucket.agent_source.arn
      },
    ]
  })
}

# ==============================================================================
# CodeBuild Project — Agent Container Image Builder
# ==============================================================================

resource "aws_codebuild_project" "agent_image" {
  name          = "${var.name}-build"
  description   = "Build and push the agent container image for ${var.name}."
  service_role  = aws_iam_role.image_build.arn
  build_timeout = var.codebuild_build_timeout

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_environment_image
    type                        = var.codebuild_environment_type
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.id
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.this.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = var.image_tag
    }
  }

  source {
    type      = "S3"
    location  = "${aws_s3_bucket.agent_source.id}/${aws_s3_object.agent_source.key}"
    buildspec = file("${path.module}/../../buildspec.yaml")
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/${var.name}-build"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.name}-build"
  })
}

# ==============================================================================
# Build Trigger (optional)
#
# Starts a CodeBuild run via a local script on every apply where any trigger
# value changes. Set trigger_build_on_apply = false to skip this step and
# manage builds out-of-band (e.g. via CI/CD or manual console runs).
#
# NOTE: Requires AWS CLI v2 and bash on the Terraform executor.
# ==============================================================================

resource "null_resource" "trigger_build" {
  count = var.trigger_build_on_apply ? 1 : 0

  triggers = {
    codebuild_project = aws_codebuild_project.agent_image.id
    image_tag         = var.image_tag
    ecr_repository    = aws_ecr_repository.this.id
    source_code_md5   = data.archive_file.agent_source.output_md5
  }

  provisioner "local-exec" {
    command = "${path.module}/../../scripts/build-image.sh \"${aws_codebuild_project.agent_image.name}\" \"${data.aws_region.current.id}\" \"${aws_ecr_repository.this.name}\" \"${var.image_tag}\" \"${aws_ecr_repository.this.repository_url}\""
  }

  depends_on = [
    aws_codebuild_project.agent_image,
    aws_ecr_repository.this,
    aws_iam_role_policy.image_build,
    aws_s3_object.agent_source,
  ]
}
