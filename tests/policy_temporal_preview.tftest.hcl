mock_provider "awscc" {
  mock_resource "awscc_bedrockagentcore_policy" {
    defaults = {
      policy_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy/temporal-policy"
    }
  }
}

run "temporal_policy_is_explicit_and_fail_closed" {
  command = apply

  module {
    source = "./modules/policy-temporal-preview"
  }

  variables {
    policy_engine_id = "PolicyEngine-abcdefghij"
    policies = {
      bounded_calls = {
        statement        = "forbid(principal, action, resource) when temporal { formerly within 1m AgentCore::Action::\"OperatorRuntime___POST:/invocations\"::response{ eventResource: resource } };"
        enforcement_mode = "ACTIVE"
      }
    }
  }

  assert {
    condition     = output.policy_arns["bounded_calls"] == "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy/temporal-policy"
    error_message = "The preview submodule must expose each temporal policy ARN."
  }
}

run "temporal_policy_defaults_to_log_only" {
  command = plan

  module {
    source = "./modules/policy-temporal-preview"
  }

  variables {
    policy_engine_id = "PolicyEngine-abcdefghij"
    policies = {
      candidate = {
        statement = "permit(principal, action, resource);"
      }
    }
  }

  assert {
    condition     = awscc_bedrockagentcore_policy.this["candidate"].enforcement_mode == "LOG_ONLY"
    error_message = "Unpromoted temporal policies must default to LOG_ONLY."
  }
}
