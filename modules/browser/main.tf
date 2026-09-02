locals {
  common_tags = merge(
    {
      Module    = "terraform-aws-agentcore"
      ManagedBy = "Terraform"
    },
    var.tags,
  )
}

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition = var.network_mode != "VPC" || (
        length(var.vpc_security_group_ids) > 0 && length(var.vpc_subnet_ids) > 0
      )
      error_message = "VPC Browser mode requires vpc_security_group_ids and vpc_subnet_ids."
    }

    precondition {
      condition     = !var.browser_signing_enabled || var.execution_role_arn != null
      error_message = "Browser request signing requires execution_role_arn."
    }
  }
}

resource "aws_bedrockagentcore_browser" "this" {
  count = var.create_browser ? 1 : 0

  name               = replace(var.name, "-", "_")
  description        = var.description
  execution_role_arn = var.execution_role_arn
  tags               = local.common_tags

  browser_signing {
    enabled = var.browser_signing_enabled
  }

  dynamic "certificate" {
    for_each = var.certificate_secret_arn == null ? [] : [var.certificate_secret_arn]
    content {
      location {
        secrets_manager {
          secret_arn = certificate.value
        }
      }
    }
  }

  dynamic "enterprise_policy" {
    for_each = var.enterprise_policy == null ? [] : [var.enterprise_policy]
    content {
      type = enterprise_policy.value.type
      location {
        s3 {
          bucket     = enterprise_policy.value.bucket
          prefix     = enterprise_policy.value.prefix
          version_id = enterprise_policy.value.version_id
        }
      }
    }
  }

  network_configuration {
    network_mode = var.network_mode

    dynamic "vpc_config" {
      for_each = var.network_mode == "VPC" ? [1] : []
      content {
        security_groups = var.vpc_security_group_ids
        subnets         = var.vpc_subnet_ids
      }
    }
  }

  dynamic "recording" {
    for_each = var.recording == null ? [] : [var.recording]
    content {
      enabled = recording.value.enabled
      s3_location {
        bucket = recording.value.bucket
        prefix = recording.value.prefix
      }
    }
  }

  depends_on = [terraform_data.validations]
}

resource "aws_bedrockagentcore_browser_profile" "this" {
  for_each = var.profiles

  name        = replace(coalesce(each.value.name, "${var.name}_${each.key}"), "-", "_")
  description = each.value.description
  tags        = local.common_tags
}
