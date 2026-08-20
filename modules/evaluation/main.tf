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
      condition = alltrue(flatten([
        for config in values(var.online_evaluations) : [
          for key in config.evaluator_keys : contains(keys(var.evaluators), key)
        ]
      ]))
      error_message = "Every online_evaluations evaluator_key must exist in evaluators."
    }
  }
}

resource "aws_bedrockagentcore_evaluator" "this" {
  for_each = var.evaluators

  evaluator_name = replace(coalesce(each.value.name, "${var.name}_${each.key}"), "-", "_")
  description    = each.value.description
  level          = each.value.level
  kms_key_arn    = each.value.kms_key_arn
  tags           = local.common_tags

  evaluator_config {
    dynamic "code_based" {
      for_each = each.value.code_based == null ? [] : [each.value.code_based]
      content {
        lambda_config {
          lambda_arn                = code_based.value.lambda_arn
          lambda_timeout_in_seconds = code_based.value.timeout_seconds
        }
      }
    }

    dynamic "llm_as_a_judge" {
      for_each = each.value.llm_judge == null ? [] : [each.value.llm_judge]
      content {
        instructions = llm_as_a_judge.value.instructions

        model_config {
          bedrock_evaluator_model_config {
            model_id = llm_as_a_judge.value.model_id
            inference_config {
              max_tokens  = llm_as_a_judge.value.max_tokens
              temperature = llm_as_a_judge.value.temperature
              top_p       = llm_as_a_judge.value.top_p
            }
          }
        }

        rating_scale {
          dynamic "categorical" {
            for_each = llm_as_a_judge.value.categories
            content {
              label      = categorical.value.label
              definition = categorical.value.definition
            }
          }
        }
      }
    }
  }
}

resource "aws_bedrockagentcore_online_evaluation_config" "this" {
  for_each = var.online_evaluations

  online_evaluation_config_name = replace(coalesce(each.value.name, "${var.name}_${each.key}"), "-", "_")
  description                   = each.value.description
  evaluation_execution_role_arn = each.value.execution_role_arn
  enable_on_create              = each.value.enable_on_create
  tags                          = local.common_tags

  data_source_config {
    cloudwatch_logs {
      log_group_names = each.value.log_group_names
      service_names   = each.value.service_names
    }
  }

  dynamic "evaluator" {
    for_each = setunion(
      toset([for key in each.value.evaluator_keys : aws_bedrockagentcore_evaluator.this[key].evaluator_id]),
      each.value.evaluator_ids,
    )
    content {
      evaluator_id = evaluator.value
    }
  }

  rule {
    sampling_config {
      sampling_percentage = each.value.sampling_percentage
    }

    session_config {
      session_timeout_minutes = each.value.session_timeout_minutes
    }
  }

  depends_on = [terraform_data.validations]
}
