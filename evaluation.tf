resource "aws_bedrockagentcore_evaluator" "this" {
  for_each = var.evaluators

  evaluator_name = each.value.name
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

  online_evaluation_config_name = each.value.name
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
    for_each = each.value.evaluator_keys
    content {
      evaluator_id = aws_bedrockagentcore_evaluator.this[evaluator.value].evaluator_id
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
}

resource "aws_cloudwatch_log_group" "observability" {
  for_each = var.observability

  name              = each.value.log_group_name
  retention_in_days = each.value.retention_in_days
  kms_key_id        = each.value.kms_key_arn
  tags              = local.common_tags
}

module "preview" {
  for_each = var.preview_stacks
  source   = "./modules/preview"

  name          = each.value.name
  template_body = each.value.template_body
  parameters    = each.value.parameters
  capabilities  = each.value.capabilities
  tags          = local.common_tags
}

module "agent_registry_preview" {
  for_each = var.registries
  source   = "./modules/agent-registry-preview"

  name               = each.value.name
  log_retention_days = each.value.log_retention_days
  tags               = local.common_tags
}
