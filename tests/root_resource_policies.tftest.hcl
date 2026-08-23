mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-agentcore-role"
      id  = "mock-agentcore-role"
    }
  }

  mock_resource "aws_bedrockagentcore_agent_runtime" {
    defaults = {
      agent_runtime_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/Provider-a1b2c3d4e5"
    }
  }

  mock_resource "aws_bedrockagentcore_gateway" {
    defaults = {
      gateway_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/Provider-a1b2c3d4e5"
      gateway_id  = "Provider-a1b2c3d4e5"
      gateway_url = "https://example.gateway.bedrock-agentcore.us-east-1.amazonaws.com"
    }
  }
}

mock_provider "archive" {}
mock_provider "null" {}
mock_provider "time" {}

run "root_instance_owns_gateway_and_runtime_resource_policies" {
  command = apply

  variables {
    name                          = "provider"
    create_runtime                = true
    create_execution_role         = true
    image_uri                     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/provider:test"
    create_gateway                = true
    gateway_attach_runtime_target = true

    gateway_resource_policy_configuration = {
      role_arns = ["arn:aws:iam::111122223333:role/tenant-gateway"]
    }

    runtime_resource_policy_configuration = {
      allow_gateway_role = true
    }
  }

  assert {
    condition     = output.resource_policies["gateway"].resource_arn == output.gateway_arn
    error_message = "The root module must attach the Gateway policy to its own Gateway."
  }

  assert {
    condition     = output.resource_policies["runtime"].resource_arn == output.agent_runtime_arn
    error_message = "The root module must attach the Runtime policy to its own Runtime."
  }

  assert {
    condition     = strcontains(output.resource_policies["gateway"].policy, "arn:aws:iam::111122223333:role/tenant-gateway")
    error_message = "The Gateway policy must allow the configured cross-account role."
  }

  assert {
    condition     = strcontains(output.resource_policies["runtime"].policy, output.gateway_role_arn)
    error_message = "The Runtime policy must allow only the root module's Gateway role."
  }

  assert {
    condition = alltrue([
      for statement in jsondecode(output.resource_policies["gateway"].policy).Statement :
      statement.Resource == output.gateway_arn
    ])
    error_message = "Every Gateway statement must use the exact ARN of the attached Gateway."
  }

  assert {
    condition = alltrue([
      for statement in jsondecode(output.resource_policies["runtime"].policy).Statement :
      statement.Resource == output.agent_runtime_arn
    ])
    error_message = "Every Runtime statement must use the exact ARN of the attached Runtime."
  }
}

run "empty_gateway_role_list_is_fail_closed" {
  command = apply

  variables {
    name           = "closed-gateway"
    create_gateway = true

    gateway_resource_policy_configuration = {
      role_arns = []
    }
  }

  assert {
    condition     = length(jsondecode(output.resource_policies["gateway"].policy).Statement) == 1
    error_message = "An empty Gateway role list must produce only the deny-all statement."
  }

  assert {
    condition     = jsondecode(output.resource_policies["gateway"].policy).Statement[0].Effect == "Deny"
    error_message = "An empty Gateway role list must fail closed."
  }
}

run "gateway_policy_requires_an_iam_gateway" {
  command = plan

  variables {
    name = "missing-gateway"

    gateway_resource_policy_configuration = {
      role_arns = []
    }
  }

  expect_failures = [terraform_data.validations]
}

run "runtime_gateway_role_requires_a_gateway" {
  command = plan

  variables {
    name                  = "missing-runtime-gateway"
    create_runtime        = true
    create_execution_role = true
    image_uri             = "123456789012.dkr.ecr.us-east-1.amazonaws.com/runtime:test"

    runtime_resource_policy_configuration = {
      allow_gateway_role = true
    }
  }

  expect_failures = [terraform_data.validations]
}
