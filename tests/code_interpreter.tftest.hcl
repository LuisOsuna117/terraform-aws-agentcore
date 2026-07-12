mock_provider "aws" {}
mock_provider "archive" {}
mock_provider "null" {}
mock_provider "time" {}

run "runtime_with_code_interpreter" {
  command = plan

  override_resource {
    target = aws_iam_role.agent_execution
    values = {
      arn = "arn:aws:iam::123456789012:role/analytics-agent-execution-role"
      id  = "analytics-agent-execution-role"
    }
  }

  variables {
    name                    = "analytics-agent"
    create_build_pipeline   = false
    image_uri               = "123456789012.dkr.ecr.us-east-1.amazonaws.com/analytics-agent:test"
    create_code_interpreter = true
  }

  assert {
    condition     = output.code_interpreter_name == "analytics_agent"
    error_message = "The Code Interpreter name must default to the normalized module name."
  }

  assert {
    condition     = output.code_interpreter_network_mode == "SANDBOX"
    error_message = "The Code Interpreter must default to SANDBOX network mode."
  }
}
