mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-agentcore-role"
      id  = "mock-agentcore-role"
    }
  }
}
mock_provider "time" {}

run "gateway_exposes_advanced_auth_policy_and_streaming" {
  command = plan

  module {
    source = "./modules/gateway"
  }

  variables {
    name            = "governed-gateway"
    authorizer_type = "CUSTOM_JWT"
    authorizer_configuration = {
      discovery_url            = "https://example.auth.us-east-1.amazoncognito.com/.well-known/openid-configuration"
      allowed_audience         = ["operator-api"]
      allowed_clients          = ["portal"]
      allowed_scopes           = ["openid"]
      workload_identities      = ["arn:aws:bedrock-agentcore:us-east-1:123456789012:workload-identity-directory/default/workload-identity/operator"]
      hosting_environment_arns = ["arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/operator-abcdefghij"]
      custom_claims = [{
        inbound_token_claim_name       = "cognito:groups"
        inbound_token_claim_value_type = "STRING_ARRAY"
        claim_match_operator           = "CONTAINS"
        match_value_string             = "operators"
      }]
    }
    protocol_type = "MCP"
    protocol_configuration = {
      supported_versions         = ["2025-06-18"]
      session_timeout_in_seconds = 3600
      enable_response_streaming  = true
    }
    policy_engine_configuration = {
      arn  = "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy-engine/PolicyEngine-abcdefghij"
      mode = "ENFORCE"
    }
  }

  assert {
    condition     = aws_bedrockagentcore_gateway.this.authorizer_configuration[0].custom_jwt_authorizer[0].allowed_scopes == toset(["openid"])
    error_message = "Gateway must preserve JWT scopes."
  }

  assert {
    condition     = one(aws_bedrockagentcore_gateway.this.authorizer_configuration[0].custom_jwt_authorizer[0].custom_claim).inbound_token_claim_value_type == "STRING_ARRAY"
    error_message = "Gateway must preserve STRING_ARRAY custom claims."
  }

  assert {
    condition     = aws_bedrockagentcore_gateway.this.policy_engine_configuration[0].mode == "ENFORCE"
    error_message = "Gateway must attach the requested Policy Engine mode."
  }

  assert {
    condition     = aws_bedrockagentcore_gateway.this.protocol_configuration[0].mcp[0].streaming_configuration[0].enable_response_streaming
    error_message = "Gateway must expose MCP response streaming."
  }
}

run "gateway_created_role_gets_inferred_target_permissions" {
  command = plan

  module {
    source = "./modules/gateway"
  }

  variables {
    name          = "target-gateway"
    protocol_type = "MCP"
    interceptor_configurations = [{
      interception_points = ["REQUEST"]
      lambda_arn          = "arn:aws:lambda:us-east-1:123456789012:function:gateway-interceptor"
    }]
    policy_engine_configuration = {
      arn  = "arn:aws:bedrock-agentcore:us-east-1:123456789012:policy-engine/PolicyEngine-abcdefghij"
      mode = "ENFORCE"
    }
    targets = {
      lambda = {
        target_configuration = {
          mcp = {
            lambda = {
              lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:gateway-target"
              tool_schema = {
                inline_payload = {
                  name         = "lookup"
                  description  = "Look up a resource"
                  input_schema = { type = "object" }
                }
              }
            }
          }
        }
        credential_provider_configuration = { gateway_iam_role = {} }
      }
      api = {
        target_configuration = {
          mcp = {
            api_gateway = {
              rest_api_id                    = "abcdefghij"
              stage                          = "v1"
              api_gateway_tool_configuration = {}
            }
          }
        }
        credential_provider_configuration = { gateway_iam_role = {} }
      }
      schema = {
        target_configuration = {
          mcp = {
            open_api_schema = {
              s3 = { uri = "s3://agentcore-schemas/service.json" }
            }
          }
        }
      }
    }
  }

  assert {
    condition = alltrue([
      contains(flatten([for statement in jsondecode(one(aws_iam_role_policy.gateway_permissions).policy).Statement : tolist(statement.Action)]), "lambda:InvokeFunction"),
      contains(flatten([for statement in jsondecode(one(aws_iam_role_policy.gateway_permissions).policy).Statement : tolist(statement.Action)]), "execute-api:Invoke"),
      contains(flatten([for statement in jsondecode(one(aws_iam_role_policy.gateway_permissions).policy).Statement : tolist(statement.Action)]), "s3:GetObject"),
      contains(flatten([for statement in jsondecode(one(aws_iam_role_policy.gateway_permissions).policy).Statement : tolist(statement.Action)]), "bedrock-agentcore:AuthorizeAction"),
    ])
    error_message = "The module-created Gateway role must infer permissions for configured AWS targets and Policy Engine."
  }
}

run "existing_gateway_role_is_never_mutated" {
  command = plan

  module {
    source = "./modules/gateway"
  }

  variables {
    name        = "external-role-gateway"
    create_role = false
    role_arn    = "arn:aws:iam::123456789012:role/external-gateway-role"
    targets = {
      runtime = {
        target_configuration = {
          http = {
            agentcore_runtime = {
              arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/Operator-abcdefghij"
            }
          }
        }
        credential_provider_configuration = { gateway_iam_role = {} }
      }
    }
  }

  assert {
    condition     = length(aws_iam_role_policy.gateway_permissions) == 0 && length(aws_iam_role_policy_attachment.gateway) == 0
    error_message = "Using an existing Gateway role must not attach or create IAM policies."
  }
}
