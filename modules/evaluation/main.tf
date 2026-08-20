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
  region         = each.value.region
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
            model_id                        = llm_as_a_judge.value.model_id
            additional_model_request_fields = llm_as_a_judge.value.additional_model_request_fields
            inference_config {
              max_tokens     = llm_as_a_judge.value.max_tokens
              temperature    = llm_as_a_judge.value.temperature
              top_p          = llm_as_a_judge.value.top_p
              stop_sequences = llm_as_a_judge.value.stop_sequences
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

          dynamic "numerical" {
            for_each = llm_as_a_judge.value.numerical
            content {
              label      = numerical.value.label
              definition = numerical.value.definition
              value      = numerical.value.value
            }
          }
        }
      }
    }
  }

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "aws_bedrockagentcore_online_evaluation_config" "this" {
  for_each = var.online_evaluations

  online_evaluation_config_name = replace(coalesce(each.value.name, "${var.name}_${each.key}"), "-", "_")
  description                   = each.value.description
  evaluation_execution_role_arn = each.value.execution_role_arn
  enable_on_create              = each.value.enable_on_create
  region                        = each.value.region
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
    dynamic "filter" {
      for_each = each.value.filters
      content {
        key      = filter.value.key
        operator = filter.value.operator

        value {
          boolean_value = filter.value.value.boolean_value
          double_value  = filter.value.value.double_value
          string_value  = filter.value.value.string_value
        }
      }
    }

    sampling_config {
      sampling_percentage = each.value.sampling_percentage
    }

    session_config {
      session_timeout_minutes = each.value.session_timeout_minutes
    }
  }

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [terraform_data.validations]
}
