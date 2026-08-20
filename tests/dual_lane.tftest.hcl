mock_provider "aws" {
  mock_resource "aws_bedrockagentcore_policy_engine" {
    defaults = {
      policy_engine_id  = "engine-1234567890"
      policy_engine_arn = "arn:aws:bedrock-agentcore:us-east-1:111122223333:policy-engine/engine-1234567890"
    }
  }

  mock_resource "aws_bedrockagentcore_gateway" {
    defaults = {
      gateway_id  = "gateway-1234567890"
      gateway_arn = "arn:aws:bedrock-agentcore:us-east-1:111122223333:gateway/gateway-1234567890"
      gateway_url = "https://gateway.example.test"
    }
  }

  mock_resource "aws_bedrockagentcore_agent_runtime" {
    defaults = {
      agent_runtime_id  = "runtime-1234567890"
      agent_runtime_arn = "arn:aws:bedrock-agentcore:us-east-1:111122223333:runtime/runtime-1234567890"
    }
  }
}

run "dual_lane_is_fail_closed" {
  command = plan

  variables {
    runtimes = {
      operator = {
        name           = "aegis_operator"
        role_arn       = "arn:aws:iam::111122223333:role/aegis-operator"
        image_uri      = "111122223333.dkr.ecr.us-east-1.amazonaws.com/aegis@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        authentication = "CUSTOM_JWT"
        jwt = {
          discovery_url       = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_example/.well-known/openid-configuration"
          allowed_clients     = ["portal-client"]
          allowed_gateway_key = "human"
          claims = [{
            name        = "cognito:groups"
            value_type  = "STRING_ARRAY"
            operator    = "CONTAINS"
            string_list = ["aegis-itops-cloud-investigator"]
          }]
        }
      }
      automation = {
        name                           = "aegis_automation"
        role_arn                       = "arn:aws:iam::111122223333:role/aegis-automation"
        image_uri                      = "111122223333.dkr.ecr.us-east-1.amazonaws.com/aegis@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        authentication                 = "AWS_IAM"
        browser_id_environment         = { AGENTCORE_BROWSER_ID = "readonly" }
        browser_profile_id_environment = { AGENTCORE_BROWSER_PROFILE_ID = "readonly" }
      }
    }

    policy_engines = {
      itops = { name = "aegis_itops" }
    }

    gateways = {
      human = {
        name              = "aegis-human"
        role_arn          = "arn:aws:iam::111122223333:role/aegis-human-gateway"
        authentication    = "CUSTOM_JWT"
        policy_engine_key = "itops"
        jwt = {
          discovery_url   = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_example/.well-known/openid-configuration"
          allowed_clients = ["portal-client"]
        }
      }
      automation = {
        name              = "aegis-automation"
        role_arn          = "arn:aws:iam::111122223333:role/aegis-automation-gateway"
        authentication    = "AWS_IAM"
        policy_engine_key = "itops"
      }
    }

    gateway_targets = {
      human = {
        gateway_key     = "human"
        name            = "operator-runtime"
        target_type     = "HTTP_RUNTIME"
        runtime_key     = "operator"
        credential_mode = "JWT_PASSTHROUGH"
      }
      automation = {
        gateway_key     = "automation"
        name            = "automation-runtime"
        target_type     = "HTTP_RUNTIME"
        runtime_key     = "automation"
        credential_mode = "GATEWAY_IAM_ROLE"
      }
      human_tools = {
        gateway_key     = "human"
        name            = "read-tools"
        target_type     = "MCP_SERVER"
        mcp_endpoint    = "https://tools.example.test/mcp"
        credential_mode = "GATEWAY_IAM_ROLE"
        signing_service = "execute-api"
      }
    }

    runtime_role_permissions = {
      operator = {
        runtime_key = "operator"
        statements = [{
          sid          = "InvokeHumanGateway"
          actions      = ["bedrock-agentcore:InvokeGateway"]
          gateway_keys = ["human"]
        }]
      }
    }

    gateway_role_permissions = {
      human = {
        gateway_key = "human"
        statements = [{
          sid          = "InvokeOperatorRuntime"
          actions      = ["bedrock-agentcore:InvokeAgentRuntime"]
          runtime_keys = ["operator"]
        }]
      }
    }

    code_interpreters = {
      isolated = { name = "aegis_ci" }
    }

    browsers = {
      readonly = { name = "aegis_readonly_browser" }
    }

    browser_profiles = {
      readonly = { name = "aegis_readonly_profile" }
    }

    observability = {
      usage = { log_group_name = "/aws/bedrock-agentcore/aegis/usage" }
    }

    registries = {
      shadow = {
        name = "aegis_shadow_registry"
      }
    }
  }

  assert {
    condition     = length(aws_bedrockagentcore_agent_runtime.this["operator"].authorizer_configuration) == 1
    error_message = "Operator Runtime must use CUSTOM_JWT."
  }

  assert {
    condition     = strcontains(aws_iam_role_policy.runtime["operator"].policy, aws_bedrockagentcore_gateway.this["human"].gateway_arn)
    error_message = "Runtime IAM must resolve exact module-managed Gateway resources."
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.this["human_tools"].target_configuration[0].mcp[0].mcp_server[0].endpoint == "https://tools.example.test/mcp"
    error_message = "The v1 module must expose governed MCP server targets."
  }

  assert {
    condition     = length(aws_bedrockagentcore_agent_runtime.this["automation"].authorizer_configuration) == 0
    error_message = "Automation Runtime must not carry a human JWT authorizer."
  }

  assert {
    condition     = aws_bedrockagentcore_gateway.this["human"].policy_engine_configuration[0].mode == "ENFORCE" && aws_bedrockagentcore_gateway.this["automation"].policy_engine_configuration[0].mode == "ENFORCE"
    error_message = "Both Gateways must enforce Cedar policy."
  }

  assert {
    condition     = length(aws_bedrockagentcore_gateway_target.this["human"].credential_provider_configuration[0].jwt_passthrough) == 1
    error_message = "Human Gateway must preserve the validated bearer context."
  }

  assert {
    condition     = length(aws_bedrockagentcore_gateway_target.this["automation"].credential_provider_configuration[0].gateway_iam_role) == 1
    error_message = "Automation Gateway must use its IAM role."
  }

  assert {
    condition     = aws_bedrockagentcore_code_interpreter.this["isolated"].network_configuration[0].network_mode == "SANDBOX"
    error_message = "Code Interpreter must default to the no-network sandbox."
  }

  assert {
    condition     = aws_bedrockagentcore_agent_runtime.this["automation"].environment_variables["AGENTCORE_BROWSER_PROFILE_ID"] == aws_bedrockagentcore_browser_profile.this["readonly"].profile_id
    error_message = "Automation Runtime must receive the managed Browser Profile ID."
  }

  assert {
    condition     = aws_cloudwatch_log_group.observability["usage"].retention_in_days == 365
    error_message = "Usage telemetry must retain metadata for 365 days."
  }

  assert {
    condition     = length(module.agent_registry_preview) == 1
    error_message = "Registry Preview must use the isolated current-namespace implementation."
  }
}
