# ==============================================================================
# S3 Bucket — Agent Source Code
# ==============================================================================

resource "aws_s3_bucket" "agent_source" {
  # bucket_prefix generates a unique name; a fixed name would cause conflicts
  # across accounts and regions when this module is used multiple times.
  bucket_prefix = "${var.name}-agent-source-"

  # force_destroy defaults to false; set source_bucket_force_destroy = true
  # in non-production environments where you want a clean terraform destroy.
  force_destroy = var.source_bucket_force_destroy

  tags = merge(local.common_tags, {
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

# ==============================================================================
# Agent Source Code Archive
# ==============================================================================

# The entire agent-code directory (or the caller-supplied path) is zipped and
# stored in S3. The MD5 hash is used as part of the object key so that
# CodeBuild is re-triggered automatically when the source code changes.
data "archive_file" "agent_source" {
  type        = "zip"
  source_dir  = local.agent_source_dir
  output_path = "${path.module}/.terraform/agent-source.zip"
}

resource "aws_s3_object" "agent_source" {
  bucket = aws_s3_bucket.agent_source.id
  key    = "agent-source-${data.archive_file.agent_source.output_md5}.zip"
  source = data.archive_file.agent_source.output_path
  etag   = data.archive_file.agent_source.output_md5

  tags = merge(local.common_tags, {
    Name       = "agent-source"
    ArchiveMD5 = data.archive_file.agent_source.output_md5
  })
}
