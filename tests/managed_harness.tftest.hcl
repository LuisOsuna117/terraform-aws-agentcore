mock_provider "aws" {}

run "managed_harness_has_explicit_limits" {
  command = plan

  module {
    source = "./modules/managed-harness"
  }

  variables {
    name               = "research-harness"
    execution_role_arn = "arn:aws:iam::123456789012:role/agentcore-harness"
    image_uri          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/research:1"
    model_id           = "us.anthropic.claude-sonnet-4-6"
    system_prompt      = "Research using only the allowed tools."
    max_iterations     = 8
    max_tokens         = 4096
    timeout_seconds    = 300
  }

  assert {
    condition     = aws_bedrockagentcore_harness.this.max_iterations == 8
    error_message = "Managed Harness limits must be explicit and caller-controlled."
  }

  assert {
    condition     = aws_bedrockagentcore_harness.this.memory[0].disabled != null
    error_message = "Memory must default to disabled until the caller opts into a Memory ARN."
  }
}
