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
      gateway_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/Gateway-a1b2c3d4e5"
      gateway_id  = "Gateway-a1b2c3d4e5"
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
        PolicyArn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy-engine/operations-a1b2c3d4e5/policy/bounded-a1b2c3d4e5"
      }
    }
  }
}

mock_provider "archive" {}
mock_provider "null" {}
mock_provider "time" {}

run "one_instance_composes_only_enabled_agentcore_capabilities" {
  command = apply

  variables {
    name                  = "operations"
    create_runtime        = true
    create_execution_role = true
    image_uri             = "123456789012.dkr.ecr.us-east-1.amazonaws.com/operations@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    create_gateway        = true
    create_memory         = true

    create_browser       = true
    create_policy_engine = true
    create_evaluations   = true

    gateway_policy_engine_mode = "ENFORCE"

    additional_runtimes = {
      automation = {
        enabled               = true
        name                  = "operations-automation"
        create_execution_role = true
        image_uri             = "123456789012.dkr.ecr.us-east-1.amazonaws.com/operations@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      }
      disabled = {
        enabled            = false
        name               = "operations-disabled"
        execution_role_arn = "arn:aws:iam::123456789012:role/operations-disabled"
        image_uri          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/operations@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      }
      signal = {
        enabled            = true
        name               = "operations-signal"
        execution_role_arn = "arn:aws:iam::123456789012:role/operations-signal"
        image_uri          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/operations@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        resource_policy_configuration = {
          role_arns = ["arn:aws:iam::123456789012:role/signal-dispatcher"]
        }
      }
    }

    additional_gateways = {
      automation = {
        enabled                   = true
        name                      = "operations-automation"
        authorizer_type           = "AWS_IAM"
        runtime_key               = "automation"
        policy_engine_mode        = "ENFORCE"
        resource_policy_role_arns = ["arn:aws:iam::123456789012:role/effect-dispatcher"]
      }
      tools = {
        enabled            = true
        name               = "operations-tools"
        authorizer_type    = "CUSTOM_JWT"
        policy_engine_mode = "ENFORCE"
        authorizer_configuration = {
          discovery_url   = "https://example.auth.us-east-1.amazoncognito.com/.well-known/openid-configuration"
          allowed_clients = ["portal"]
        }
      }
    }

    gateway_policy_templates = {
      tools = {
        gateway_key        = "tools"
        statement_template = "permit(principal, action, resource == AgentCore::Gateway::\"$${gateway_arn}\");"
      }
    }

    temporal_policy_templates = {
      bounded = {
        gateway_key        = "primary"
        statement_template = "when request.resource == \"$${gateway_arn}\""
        enforcement_mode   = "ACTIVE"
      }
    }

    online_evaluations = {
      operator = {
        runtime_key             = "primary"
        execution_role_arn      = "arn:aws:iam::123456789012:role/evaluations"
        evaluator_ids           = ["Builtin.Helpfulness"]
        sampling_percentage     = 1
        session_timeout_minutes = 15
      }
    }
  }

  assert {
    condition     = toset(keys(output.additional_agent_runtimes)) == toset(["automation", "signal"])
    error_message = "Only enabled additional runtimes must be created."
  }

  assert {
    condition = (
      output.additional_agent_runtimes["automation"].execution_role_arn == "arn:aws:iam::123456789012:role/mock-agentcore-role" &&
      output.additional_agent_runtimes["signal"].execution_role_arn == "arn:aws:iam::123456789012:role/operations-signal"
    )
    error_message = "Additional runtimes must support both module-created and caller-owned execution roles."
  }

  assert {
    condition     = toset(keys(output.additional_gateways)) == toset(["automation", "tools"])
    error_message = "Only enabled additional gateways must be created."
  }

  assert {
    condition     = output.policy_engine_id != null && output.browser_id != null
    error_message = "Policy and Browser must be owned by the root instance when enabled."
  }

  assert {
    condition     = contains(keys(output.policy_arns), "tools") && contains(keys(output.policy_arns), "bounded")
    error_message = "Cedar and temporal policies must be created from root inputs."
  }

  assert {
    condition     = contains(keys(output.online_evaluations), "operator")
    error_message = "Online evaluations must be created from root inputs."
  }

  assert {
    condition = (
      contains(keys(output.resource_policies), "gateway_automation") &&
      contains(keys(output.resource_policies), "runtime_signal") &&
      output.additional_gateways["automation"].runtime_target_id != null
    )
    error_message = "Composed Gateway/Runtime trust and attached targets must be managed in the same root instance."
  }

  assert {
    condition = anytrue([
      for statement in jsondecode(aws_iam_role_policy.additional_runtime["automation"].policy).Statement :
      statement.Effect == "Deny" && contains(statement.Action, "bedrock-agentcore:GetWorkloadAccessTokenForUserId")
    ])
    error_message = "Module-created additional Runtime roles must deny arbitrary user-id token minting by default."
  }
}

run "additional_runtime_role_selection_is_explicit" {
  command = plan

  variables {
    name = "invalid-role-selection"
    additional_runtimes = {
      missing_role = {
        name      = "missing-role"
        image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/operations@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      }
    }
  }

  expect_failures = [var.additional_runtimes]
}
