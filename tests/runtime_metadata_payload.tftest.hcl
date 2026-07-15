mock_provider "aws" {
  mock_resource "aws_bedrockagentcore_agent_runtime" {
    defaults = {
      agent_runtime_id = "PayloadAgent-a1b2c3d4e5"
    }
  }
}
mock_provider "local" {}

run "update_payload_preserves_runtime_configuration" {
  command = plan

  module {
    source = "./modules/runtime"
  }

  variables {
    runtime_name       = "payload_agent"
    execution_role_arn = "arn:aws:iam::123456789012:role/payload-agent-role"
    image_uri          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/payload-agent:test"

    network_mode           = "VPC"
    vpc_security_group_ids = ["sg-1234567890abcdef0"]
    vpc_subnet_ids         = ["subnet-1234567890abcdef0"]

    authorizer_discovery_url    = "https://auth.example.com/.well-known/openid-configuration"
    authorizer_allowed_audience = ["payload-api"]
    authorizer_allowed_clients  = ["payload-client"]

    idle_runtime_session_timeout = 900
    max_lifetime                 = 3600
    server_protocol              = "MCP"
    request_header_allowlist     = ["X-Correlation-Id"]
    environment_variables        = { MODE = "test" }
  }

  assert {
    condition     = jsondecode(nonsensitive(local_sensitive_file.runtime_update_input[0].content)).metadataConfiguration.requireMMDSV2
    error_message = "The UpdateAgentRuntime payload must require MMDSv2 by default."
  }

  assert {
    condition = jsondecode(nonsensitive(local_sensitive_file.runtime_update_input[0].content)).networkConfiguration == {
      networkMode = "VPC"
      networkModeConfig = {
        securityGroups = ["sg-1234567890abcdef0"]
        subnets        = ["subnet-1234567890abcdef0"]
      }
    }
    error_message = "The MMDSv2 compatibility update must preserve VPC networking."
  }

  assert {
    condition = jsondecode(nonsensitive(local_sensitive_file.runtime_update_input[0].content)).authorizerConfiguration.customJWTAuthorizer == {
      discoveryUrl    = "https://auth.example.com/.well-known/openid-configuration"
      allowedAudience = ["payload-api"]
      allowedClients  = ["payload-client"]
    }
    error_message = "The MMDSv2 compatibility update must preserve the JWT authorizer."
  }
}
