locals {
  common_tags = merge(
    {
      Module    = "terraform-aws-agentcore"
      ManagedBy = "Terraform"
    },
    var.tags,
  )
  policy_engine_id = var.create_policy_engine ? aws_bedrockagentcore_policy_engine.this[0].policy_engine_id : var.policy_engine_id
}

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = length(var.policies) == 0 || var.create_policy_engine || var.policy_engine_id != null
      error_message = "policy_engine_id is required when policies are provided and create_policy_engine is false."
    }
  }
}

resource "aws_bedrockagentcore_policy_engine" "this" {
  count = var.create_policy_engine ? 1 : 0

  name               = replace(var.name, "-", "_")
  description        = var.description
  encryption_key_arn = var.encryption_key_arn
  tags               = local.common_tags
}

resource "aws_bedrockagentcore_policy" "this" {
  for_each = var.policies

  name             = replace(coalesce(each.value.name, "${var.name}_${each.key}"), "-", "_")
  description      = each.value.description
  policy_engine_id = local.policy_engine_id
  validation_mode  = each.value.validation_mode

  definition {
    cedar {
      statement = each.value.cedar_statement
    }
  }

  depends_on = [terraform_data.validations]
}

resource "aws_bedrockagentcore_resource_policy" "this" {
  for_each = var.resource_policies

  resource_arn = each.value.resource_arn
  policy       = each.value.policy
}
