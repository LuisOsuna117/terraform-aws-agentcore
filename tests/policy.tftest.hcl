mock_provider "aws" {
  mock_resource "aws_bedrockagentcore_policy_engine" {
    defaults = {
      policy_engine_id = "CommunityPolicy-abcdefghij"
    }
  }
}

run "policy_preserves_caller_owned_cedar" {
  command = plan

  module {
    source = "./modules/policy"
  }

  variables {
    name = "community-policy"

    policies = {
      read = {
        cedar_statement = "permit(principal, action, resource);"
      }
    }

    resource_policies = {
      runtime = {
        resource_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/example"
        policy       = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
      }
    }
  }

  assert {
    condition     = aws_bedrockagentcore_policy.this["read"].definition[0].cedar[0].statement == "permit(principal, action, resource);"
    error_message = "The policy module must not reinterpret caller-owned Cedar."
  }

  assert {
    condition     = length(output.policy_arns) == 1
    error_message = "The policy module must expose each created policy ARN."
  }
}

run "existing_policy_engine_is_supported" {
  command = plan

  module {
    source = "./modules/policy"
  }

  variables {
    name                 = "existing-policy"
    create_policy_engine = false
    policy_engine_id     = "ExistingPolicy-abcdefghij"

    policies = {
      read = {
        cedar_statement = "permit(principal, action, resource);"
      }
    }
  }

  assert {
    condition     = aws_bedrockagentcore_policy.this["read"].policy_engine_id == "ExistingPolicy-abcdefghij"
    error_message = "Callers must be able to attach policies to an existing policy engine."
  }
}

run "resource_policies_do_not_require_a_policy_engine" {
  command = plan

  module {
    source = "./modules/policy"
  }

  variables {
    name                 = "resource-policy-only"
    create_policy_engine = false

    resource_policies = {
      gateway = {
        resource_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/example"
        policy       = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
      }
    }
  }

  assert {
    condition     = length(aws_bedrockagentcore_policy_engine.this) == 0
    error_message = "Resource-policy-only use must not create a Policy Engine."
  }

  assert {
    condition     = aws_bedrockagentcore_resource_policy.this["gateway"].resource_arn == "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/example"
    error_message = "The module must create resource policies without a Policy Engine."
  }

  assert {
    condition     = output.policy_engine_id == null
    error_message = "Resource-policy-only use must expose a null Policy Engine ID."
  }
}

run "cedar_policies_still_require_a_policy_engine" {
  command = plan

  module {
    source = "./modules/policy"
  }

  variables {
    name                 = "missing-policy-engine"
    create_policy_engine = false

    policies = {
      read = {
        cedar_statement = "permit(principal, action, resource);"
      }
    }
  }

  expect_failures = [terraform_data.validations]
}
