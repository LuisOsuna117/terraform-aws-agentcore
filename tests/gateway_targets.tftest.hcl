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

run "agent_target_uses_general_http_gateway" {
  command = plan

  variables {
    name                  = "agent-gateway"
    create_build_pipeline = false
    create_runtime        = false
    image_uri             = "123456789012.dkr.ecr.us-east-1.amazonaws.com/agent-gateway:test"
    create_gateway        = true

    gateway_targets = {
      assistant = {
        target_type       = "AGENT"
        agent_runtime_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/Assistant-a1b2c3d4e5"
      }
    }
  }

  assert {
    condition     = output.gateway_protocol_type == null
    error_message = "An AGENT target must leave the Gateway aggregation protocol unset."
  }

  assert {
    condition     = length(output.gateway_agent_target_invocation_urls) == 1
    error_message = "An AGENT target must be rendered as an HTTP AgentCore Runtime target."
  }

  assert {
    condition     = length(output.gateway_target_endpoints) == 0
    error_message = "An AGENT target must not be rendered as an MCP aggregation target."
  }
}

run "mcp_target_infers_mcp_aggregation" {
  command = plan

  variables {
    name                  = "mcp-gateway"
    create_build_pipeline = false
    create_runtime        = false
    image_uri             = "123456789012.dkr.ecr.us-east-1.amazonaws.com/mcp-gateway:test"
    create_gateway        = true

    gateway_targets = {
      tools = {
        target_type = "MCP"
        endpoint    = "https://tools.example.com/mcp"
      }
    }
  }

  assert {
    condition     = output.gateway_protocol_type == "MCP"
    error_message = "An MCP target must infer MCP aggregation when gateway_protocol_type is null."
  }

  assert {
    condition     = length(output.gateway_target_endpoints) == 1
    error_message = "An MCP target must be rendered as an MCP Gateway target."
  }
}

run "self_runtime_defaults_to_agent_target" {
  command = plan

  variables {
    name                          = "self-agent-gateway"
    create_build_pipeline         = false
    image_uri                     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/self-agent-gateway:test"
    create_gateway                = true
    gateway_attach_runtime_target = true
  }

  assert {
    condition     = length(output.gateway_agent_target_invocation_urls) == 1
    error_message = "A default HTTP runtime attached to a general gateway must use an AGENT target."
  }
}
