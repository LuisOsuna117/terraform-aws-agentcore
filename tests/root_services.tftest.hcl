mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-agentcore-role"
      id  = "mock-agentcore-role"
    }
  }

  mock_resource "aws_bedrockagentcore_agent_runtime" {
    defaults = {
      agent_runtime_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/Runtime-a1b2c3d4e5"
      agent_runtime_id  = "Runtime-a1b2c3d4e5"
    }
  }

  mock_resource "aws_bedrockagentcore_gateway" {
    defaults = {
      gateway_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/gateway-a1b2c3d4e5"
      gateway_id  = "gateway-a1b2c3d4e5"
      gateway_url = "https://example.gateway.bedrock-agentcore.us-east-1.amazonaws.com"
    }
  }

  mock_resource "aws_bedrockagentcore_policy_engine" {
    defaults = {
      policy_engine_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy-engine/operations-a1b2c3d4e5"
      policy_engine_id  = "operations-a1b2c3d4e5"
    }
  }

  mock_resource "aws_cloudformation_stack" {
    defaults = {
      outputs = {
        PolicyArn  = "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy-engine/operations-a1b2c3d4e5/policy/bounded-a1b2c3d4e5"
        TargetId   = "web-search-a1b2c3d4e5"
        GatewayArn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/Gateway-a1b2c3d4e5"
      }
    }
  }
}

mock_provider "archive" {}
mock_provider "null" {}
mock_provider "time" {}

run "one_runtime_composes_only_its_opt_in_services" {
  command = apply

  variables {
    name                      = "operations"
    create_runtime            = true
    create_execution_role     = true
    image_uri                 = "123456789012.dkr.ecr.us-east-1.amazonaws.com/operations@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    create_gateway            = true
    create_memory             = true
    create_browser            = true
    create_policy_engine      = true
    create_evaluations        = true
    create_gateway_connectors = true

    gateway_connector_targets = {
      web_search = {
        name              = "web-search"
        connector_id      = "web-search"
        connector_version = "1.2.0"
        configurations = [{
          name = "WebSearch"
          parameter_values = {
            domainFilter = {
              include = ["docs.aws.amazon.com"]
            }
          }
        }]
      }
    }

    gateway_policy_engine_mode = "ENFORCE"

    gateway_policy_templates = {
      access = {
        statement_template = "permit(principal, action, resource == AgentCore::Gateway::\"$${gateway_arn}\");"
      }
    }

    temporal_policy_templates = {
      bounded = {
        statement_template = "when request.resource == \"$${gateway_arn}\""
        enforcement_mode   = "ACTIVE"
      }
    }

    runtime_environment_bindings = {
      AGENTCORE_MEMORY_ID  = "memory_id"
      AGENTCORE_BROWSER_ID = "browser_id"
    }
    runtime_memory_access_enabled  = true
    runtime_browser_access_enabled = true

    online_evaluations = {
      runtime = {
        use_runtime             = true
        execution_role_arn      = "arn:aws:iam::123456789012:role/evaluations"
        evaluator_ids           = ["Builtin.Helpfulness"]
        sampling_percentage     = 1
        session_timeout_minutes = 15
      }
    }
  }

  assert {
    condition     = output.policy_engine_id != null && output.browser_id != null
    error_message = "Policy and Browser must be owned by this module invocation when enabled."
  }

  assert {
    condition     = contains(keys(output.policy_arns), "access") && contains(keys(output.policy_arns), "bounded")
    error_message = "Cedar and Dogwood policies must render against this invocation's Gateway."
  }

  assert {
    condition     = contains(keys(output.online_evaluations), "runtime")
    error_message = "Online evaluations must support the Runtime created by this invocation."
  }

  assert {
    condition     = output.gateway_connector_targets["web_search"].connector_version == "1.2.0"
    error_message = "Built-in connectors must bind to this invocation's Gateway."
  }
}

run "existing_policy_engine_is_reused_without_creating_another" {
  command = plan

  variables {
    name              = "tools"
    create_gateway    = true
    policy_engine_id  = "shared-a1b2c3d4e5"
    policy_engine_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy-engine/shared-a1b2c3d4e5"

    gateway_policy_engine_mode = "ENFORCE"
    gateway_policy_templates = {
      access = {
        statement_template = "permit(principal, action, resource == AgentCore::Gateway::\"$${gateway_arn}\");"
      }
    }
  }

  assert {
    condition = (
      output.policy_engine_id == "shared-a1b2c3d4e5" &&
      output.policy_engine_arn == "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy-engine/shared-a1b2c3d4e5"
    )
    error_message = "Supplying an existing Policy Engine must preserve its identity."
  }
}
