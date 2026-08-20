mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-agentcore-role"
      id  = "mock-agentcore-role"
    }
  }

  mock_resource "aws_bedrockagentcore_agent_runtime" {
    defaults = {
      agent_runtime_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/SelfAgent-a1b2c3d4e5"
    }
  }
}
mock_provider "archive" {}
mock_provider "null" {}
mock_provider "time" {}

run "http_runtime_target_uses_general_gateway_configuration" {
  command = plan

  variables {
    name                  = "agent-gateway"
    create_build_pipeline = false
    create_runtime        = false
    image_uri             = "123456789012.dkr.ecr.us-east-1.amazonaws.com/agent-gateway:test"
    create_gateway        = true

    gateway_targets = {
      assistant = {
        target_configuration = {
          http = {
            agentcore_runtime = {
              arn       = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/Assistant-a1b2c3d4e5"
              qualifier = "DEFAULT"
            }
          }
        }
        credential_provider_configuration = {
          gateway_iam_role = {
            service = "bedrock-agentcore"
          }
        }
      }
    }
  }

  assert {
    condition     = output.gateway_protocol_type == null
    error_message = "An HTTP target must leave the Gateway aggregation protocol unset."
  }

  assert {
    condition     = length(output.gateway_target_invocation_urls) == 1
    error_message = "An HTTP Runtime target must expose its path-routed invocation URL."
  }

  assert {
    condition     = length(output.gateway_target_ids) == 1
    error_message = "A configured Gateway target must be managed by the native target resource."
  }
}

run "mcp_api_gateway_target_infers_aggregation" {
  command = plan

  variables {
    name                  = "service-gateway"
    create_build_pipeline = false
    create_runtime        = false
    image_uri             = "123456789012.dkr.ecr.us-east-1.amazonaws.com/service-gateway:test"
    create_gateway        = true

    gateway_targets = {
      service_api = {
        target_configuration = {
          mcp = {
            api_gateway = {
              rest_api_id = "abcdefghij"
              stage       = "v1"
              api_gateway_tool_configuration = {
                tool_filter = [{
                  filter_path = "/incidents/*"
                  methods     = ["GET"]
                }]
              }
            }
          }
        }
        credential_provider_configuration = {
          gateway_iam_role = {}
        }
      }
    }
  }

  assert {
    condition     = output.gateway_protocol_type == "MCP"
    error_message = "An MCP target must infer MCP aggregation when gateway_protocol_type is null."
  }

  assert {
    condition     = length(output.gateway_target_ids) == 1
    error_message = "The general Gateway target map must support API Gateway targets."
  }
}

run "self_runtime_defaults_to_http_target" {
  command = plan

  variables {
    name                          = "self-agent-gateway"
    create_build_pipeline         = false
    image_uri                     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/self-agent-gateway:test"
    create_gateway                = true
    gateway_attach_runtime_target = true
  }

  assert {
    condition     = length(output.gateway_target_invocation_urls) == 1
    error_message = "A default HTTP runtime attached to a general gateway must use an HTTP target."
  }
}

run "jwt_passthrough_does_not_grant_runtime_invoke_to_gateway_role" {
  command = plan

  module {
    source = "./modules/gateway"
  }

  variables {
    name = "human-gateway"

    targets = {
      operator = {
        target_configuration = {
          http = {
            agentcore_runtime = {
              arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/Operator-a1b2c3d4e5"
            }
          }
        }
        credential_provider_configuration = {
          jwt_passthrough = true
        }
      }
    }
  }

  assert {
    condition     = length(aws_iam_role_policy.gateway_permissions) == 0
    error_message = "JWT passthrough targets must not grant Runtime invoke permission to the Gateway IAM role."
  }
}

run "gateway_accepts_debug_exception_level" {
  command = plan

  module {
    source = "./modules/gateway"
  }

  variables {
    name            = "debug-gateway"
    exception_level = "DEBUG"
  }

  assert {
    condition     = aws_bedrockagentcore_gateway.this.exception_level == "DEBUG"
    error_message = "Gateway must expose the only exception level accepted by AgentCore."
  }
}
