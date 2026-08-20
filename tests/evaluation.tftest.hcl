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
