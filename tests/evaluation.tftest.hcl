mock_provider "aws" {
  mock_resource "aws_bedrockagentcore_evaluator" {
    defaults = {
      evaluator_id = "Evaluator-abcdefghij"
    }
  }
}

run "evaluator_and_online_sampling" {
  command = plan

  module {
    source = "./modules/evaluation"
  }

  variables {
    name = "quality"

    evaluators = {
      correctness = {
        level = "TRACE"
        code_based = {
          lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:evaluator"
        }
      }
    }

    online_evaluations = {
      sampled = {
        execution_role_arn      = "arn:aws:iam::123456789012:role/evaluation"
        evaluator_keys          = ["correctness"]
        log_group_names         = ["/aws/bedrock-agentcore/runtimes/example"]
        service_names           = ["example"]
        sampling_percentage     = 10
        session_timeout_minutes = 15
      }
    }
  }

  assert {
    condition     = aws_bedrockagentcore_online_evaluation_config.this["sampled"].rule[0].sampling_config[0].sampling_percentage == 10
    error_message = "Online evaluation sampling must preserve the caller's percentage."
  }
}

run "sampling_rejects_zero" {
  command = plan

  module {
    source = "./modules/evaluation"
  }

  variables {
    name = "quality"
    online_evaluations = {
      invalid = {
        execution_role_arn      = "arn:aws:iam::123456789012:role/evaluation"
        evaluator_ids           = ["Builtin.Helpfulness"]
        log_group_names         = ["/aws/bedrock-agentcore/runtimes/example"]
        service_names           = ["example"]
        sampling_percentage     = 0
        session_timeout_minutes = 15
      }
    }
  }

  expect_failures = [var.online_evaluations]
}

run "session_timeout_rejects_values_over_sixty" {
  command = plan

  module {
    source = "./modules/evaluation"
  }

  variables {
    name = "quality"
    online_evaluations = {
      invalid = {
        execution_role_arn      = "arn:aws:iam::123456789012:role/evaluation"
        evaluator_ids           = ["Builtin.Helpfulness"]
        log_group_names         = ["/aws/bedrock-agentcore/runtimes/example"]
        service_names           = ["example"]
        sampling_percentage     = 10
        session_timeout_minutes = 61
      }
    }
  }

  expect_failures = [var.online_evaluations]
}

run "llm_evaluator_supports_numerical_scale_and_online_filters" {
  command = plan

  module {
    source = "./modules/evaluation"
  }

  variables {
    name = "quality"
    evaluators = {
      safety = {
        level = "TRACE"
        llm_judge = {
          instructions                    = "Score the trajectory."
          model_id                        = "anthropic.claude-3-5-sonnet-20241022-v2:0"
          additional_model_request_fields = jsonencode({ thinking = { type = "disabled" } })
          stop_sequences                  = ["</score>"]
          numerical = [{
            label      = "unsafe"
            definition = "Unsafe operation"
            value      = 0
            }, {
            label      = "safe"
            definition = "Safe operation"
            value      = 1
          }]
        }
      }
    }
    online_evaluations = {
      failures = {
        execution_role_arn      = "arn:aws:iam::123456789012:role/evaluation"
        evaluator_keys          = ["safety"]
        log_group_names         = ["/aws/bedrock-agentcore/runtimes/example"]
        service_names           = ["example"]
        sampling_percentage     = 10
        session_timeout_minutes = 15
        filters = [{
          key      = "attributes.status"
          operator = "Equals"
          value    = { string_value = "FAILED" }
        }]
      }
    }
  }

  assert {
    condition     = aws_bedrockagentcore_evaluator.this["safety"].evaluator_config[0].llm_as_a_judge[0].rating_scale[0].numerical[1].value == 1
    error_message = "Evaluator must preserve numerical rating scales."
  }

  assert {
    condition     = one(aws_bedrockagentcore_evaluator.this["safety"].evaluator_config[0].llm_as_a_judge[0].model_config[0].bedrock_evaluator_model_config[0].inference_config[0].stop_sequences) == "</score>"
    error_message = "Evaluator must preserve stop sequences."
  }

  assert {
    condition     = aws_bedrockagentcore_online_evaluation_config.this["failures"].rule[0].filter[0].value[0].string_value == "FAILED"
    error_message = "Online evaluation must preserve rule filters."
  }
}
