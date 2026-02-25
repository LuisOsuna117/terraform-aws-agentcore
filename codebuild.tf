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
    privileged_mode             = true # required for Docker daemon access
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
    buildspec = file("${path.module}/buildspec.yaml")
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/${var.name}-build"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-build"
  })
}

# ==============================================================================
# Build Trigger
#
# Runs the CodeBuild project via a local script whenever the source code,
# image tag, or ECR repository changes. Requires AWS CLI and bash.
# NOTE: This provisioner runs on the machine executing Terraform (typically
#       a CI runner or a developer workstation), not in AWS.
# ==============================================================================

resource "null_resource" "trigger_build" {
  triggers = {
    codebuild_project = aws_codebuild_project.agent_image.id
    image_tag         = var.image_tag
    ecr_repository    = aws_ecr_repository.this.id
    source_code_md5   = data.archive_file.agent_source.output_md5
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/build-image.sh \"${aws_codebuild_project.agent_image.name}\" \"${data.aws_region.current.id}\" \"${aws_ecr_repository.this.name}\" \"${var.image_tag}\" \"${aws_ecr_repository.this.repository_url}\""
  }

  depends_on = [
    aws_codebuild_project.agent_image,
    aws_ecr_repository.this,
    aws_iam_role_policy.image_build,
    aws_s3_object.agent_source,
  ]
}
