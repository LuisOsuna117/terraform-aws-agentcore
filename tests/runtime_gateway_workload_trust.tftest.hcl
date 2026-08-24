mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-agentcore-role"
      id  = "mock-agentcore-role"
    }
  }

  mock_resource "aws_bedrockagentcore_gateway" {
    defaults = {
      gateway_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/operator-abcdefghij"
      workload_identity_details = [{
        workload_identity_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:workload-identity-directory/default/workload-identity/operator-gateway"
      }]
    }
  }

  mock_resource "aws_bedrockagentcore_agent_runtime" {
    defaults = {
      agent_runtime_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/operator-abcdefghij"
    }
  }
}
mock_provider "archive" {}
mock_provider "null" {}
mock_provider "time" {}

run "jwt_runtime_trusts_only_configured_and_gateway_workloads" {
  command = apply

  variables {
    name                                    = "operator"
    create_runtime                          = true
    create_execution_role                   = true
    create_gateway                          = true
    gateway_attach_runtime_target           = true
    runtime_trust_gateway_workload_identity = true
    image_uri                               = "123456789012.dkr.ecr.us-east-1.amazonaws.com/operator:v1"

    runtime_authorizer_configuration = {
      discovery_url   = "https://example.auth.us-east-1.amazoncognito.com/.well-known/openid-configuration"
      allowed_clients = ["portal"]
      workload_identities = [
        "arn:aws:bedrock-agentcore:us-east-1:123456789012:workload-identity-directory/default/workload-identity/reviewed"
      ]
    }

    gateway_runtime_target = {
      name = "OperatorRuntime"
      credential_provider_configuration = {
        jwt_passthrough = true
      }
    }
  }

  assert {
    condition = output.agent_runtime_allowed_workload_identities == tolist([
      "arn:aws:bedrock-agentcore:us-east-1:123456789012:workload-identity-directory/default/workload-identity/reviewed",
      "arn:aws:bedrock-agentcore:us-east-1:123456789012:workload-identity-directory/default/workload-identity/operator-gateway",
    ])
    error_message = "The Runtime must retain caller workloads and add the module-created Gateway workload identity."
  }
}

run "gateway_workload_trust_is_explicit" {
  command = plan

  variables {
    name                                    = "invalid-operator"
    create_runtime                          = true
    create_execution_role                   = true
    image_uri                               = "123456789012.dkr.ecr.us-east-1.amazonaws.com/operator:v1"
    runtime_trust_gateway_workload_identity = true
  }

  expect_failures = [terraform_data.validations]
}
