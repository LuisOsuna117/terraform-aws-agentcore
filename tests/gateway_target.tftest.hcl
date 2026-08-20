mock_provider "aws" {}

run "jwt_passthrough_runtime_target" {
  command = plan

  module {
    source = "./modules/gateway-target"
  }

  variables {
    gateway_identifier = "gateway-abcdefghij"
    name               = "operator-runtime"
    credential_mode    = "JWT_PASSTHROUGH"
    runtime_arn        = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/Operator-abcdefghij"
  }

  assert {
    condition     = length(aws_bedrockagentcore_gateway_target.this.credential_provider_configuration[0].jwt_passthrough) == 1
    error_message = "JWT_PASSTHROUGH must render the native Gateway credential mode."
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.this.target_configuration[0].http[0].agentcore_runtime[0].arn == "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/Operator-abcdefghij"
    error_message = "HTTP Runtime targets must preserve the Runtime ARN."
  }
}
