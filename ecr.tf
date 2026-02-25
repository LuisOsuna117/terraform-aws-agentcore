# ==============================================================================
# ECR Repository — Agent Container Registry
# ==============================================================================

resource "aws_ecr_repository" "this" {
  name                 = local.ecr_repository_name
  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  # force_delete defaults to false; set ecr_force_delete = true in
  # non-production environments where you want clean terraform destroy.
  force_delete = var.ecr_force_delete

  tags = merge(local.common_tags, {
    Name = local.ecr_repository_name
  })
}

# Repository policy — allow any principal in the same account to pull images.
resource "aws_ecr_repository_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowAccountPull"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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
