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
    create_execution_role   = true
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

run "code_interpreter_supports_certificate_and_timeouts" {
  command = plan

  module {
    source = "./modules/code-interpreter"
  }

  variables {
    name                   = "secure_interpreter"
    network_mode           = "PUBLIC"
    certificate_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:agentcore-certificate"
    region                 = "us-east-1"
    timeouts               = { create = "30m" }
  }

  assert {
    condition     = aws_bedrockagentcore_code_interpreter.this.certificate[0].location[0].secrets_manager[0].secret_arn == "arn:aws:secretsmanager:us-east-1:123456789012:secret:agentcore-certificate"
    error_message = "Code Interpreter must preserve the certificate secret ARN."
  }
}
