resource "aws_bedrockagentcore_code_interpreter" "this" {
  name               = var.name
  description        = var.description
  execution_role_arn = var.execution_role_arn
  region             = var.region

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

  tags = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }

  depends_on = [terraform_data.validations]
}
