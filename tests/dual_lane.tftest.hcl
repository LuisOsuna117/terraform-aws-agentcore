mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_resource "aws_ecr_repository" {
    defaults = {
      arn            = "arn:aws:ecr:us-east-1:111122223333:repository/image-build-agent"
      repository_url = "111122223333.dkr.ecr.us-east-1.amazonaws.com/image-build-agent"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::111122223333:role/image-build-codebuild"
      id  = "image-build-codebuild"
    }
  }

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

mock_provider "archive" {
  mock_data "archive_file" {
    defaults = {
      output_md5 = "0123456789abcdef0123456789abcdef"
    }
  }
}

mock_provider "null" {}

run "defaults_are_fully_opt_in" {
  command = plan

  variables {
    name = "opt-in"
  }

  assert {
    condition = alltrue([
      length(output.runtimes) == 0,
      length(output.runtime_endpoints) == 0,
      length(output.image_builds) == 0,
      length(output.gateways) == 0,
      length(output.gateway_targets) == 0,
      length(output.gateway_rules) == 0,
      length(output.gateway_discovery_parameters) == 0,
      length(output.workload_identities) == 0,
      length(output.api_key_credential_providers) == 0,
      length(output.oauth2_credential_providers) == 0,
      length(output.policy_engines) == 0,
      length(output.policies) == 0,
      length(output.memories) == 0,
      length(output.memory_strategies) == 0,
      length(output.browsers) == 0,
      length(output.browser_profiles) == 0,
      length(output.code_interpreters) == 0,
      length(output.harnesses) == 0,
      length(output.evaluators) == 0,
      length(output.online_evaluations) == 0,
      length(output.registries) == 0,
      length(output.observability_log_groups) == 0,
      length(output.preview_stacks) == 0,
    ])
    error_message = "Providing only the module name must create no opt-in features."
  }
}

run "image_builds_are_opt_in" {
  command = plan

  variables {
    name = "image-build"

    image_builds = {
      agent = {
        source_dir = "./examples/image-build/agent-code"
      }
    }
  }

  assert {
    condition     = output.image_builds["agent"].image_uri != null
    error_message = "An opted-in image build must expose its resulting ECR image URI."
  }
}

run "runtime_can_consume_an_opted_in_image_build" {
  command = plan

  variables {
    name = "built-runtime"

    image_builds = {
      agent = {
        source_dir = "./examples/image-build/agent-code"
      }
    }

    runtimes = {
      primary = {
        role_arn        = "arn:aws:iam::111122223333:role/built-runtime"
        image_build_key = "agent"
        authentication  = "AWS_IAM"
      }
    }
  }

  assert {
    condition     = aws_bedrockagentcore_agent_runtime.this["primary"].agent_runtime_artifact[0].container_configuration[0].container_uri == output.image_builds["agent"].image_uri
    error_message = "A Runtime image_build_key must resolve to the selected build output."
  }
}

run "minimal_runtime_uses_module_name" {
  command = plan

  variables {
    name = "example"

    runtimes = {
      primary = {
        role_arn       = "arn:aws:iam::111122223333:role/example-runtime"
        image_uri      = "111122223333.dkr.ecr.us-east-1.amazonaws.com/example@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        authentication = "AWS_IAM"
      }
    }
  }

  assert {
    condition     = aws_bedrockagentcore_agent_runtime.this["primary"].agent_runtime_name == "example_primary"
    error_message = "Resource names should default from the module name and map key."
  }
}

run "create_false_creates_nothing" {
  command = plan

  variables {
    create = false
    name   = "disabled"

    runtimes = {
      primary = {
        role_arn       = "arn:aws:iam::111122223333:role/example-runtime"
        image_uri      = "111122223333.dkr.ecr.us-east-1.amazonaws.com/example@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        authentication = "AWS_IAM"
      }
    }
  }

  assert {
    condition     = length(aws_bedrockagentcore_agent_runtime.this) == 0
    error_message = "create=false should disable all module resources."
  }
}

run "dual_lane_is_fail_closed" {
  command = plan

  variables {
    name = "example"

    runtimes = {
      operator = {
        name           = "example_operator"
        role_arn       = "arn:aws:iam::111122223333:role/example-operator"
        image_uri      = "111122223333.dkr.ecr.us-east-1.amazonaws.com/example@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        authentication = "CUSTOM_JWT"
        jwt = {
          discovery_url       = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_example/.well-known/openid-configuration"
          allowed_clients     = ["portal-client"]
          allowed_gateway_key = "human"
          claims = [{
            name        = "cognito:groups"
            value_type  = "STRING_ARRAY"
            operator    = "CONTAINS"
            string_list = ["example-operators"]
          }]
        }
      }
      automation = {
        name                           = "example_automation"
        role_arn                       = "arn:aws:iam::111122223333:role/example-automation"
        image_uri                      = "111122223333.dkr.ecr.us-east-1.amazonaws.com/example@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        authentication                 = "AWS_IAM"
        browser_id_environment         = { AGENTCORE_BROWSER_ID = "readonly" }
        browser_profile_id_environment = { AGENTCORE_BROWSER_PROFILE_ID = "readonly" }
      }
    }

    policy_engines = {
      access = { name = "example_access" }
    }

    gateways = {
      human = {
        name              = "example-human"
        role_arn          = "arn:aws:iam::111122223333:role/example-human-gateway"
        authentication    = "CUSTOM_JWT"
        policy_engine_key = "access"
        jwt = {
          discovery_url   = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_example/.well-known/openid-configuration"
          allowed_clients = ["portal-client"]
        }
      }
      automation = {
        name              = "example-automation"
        role_arn          = "arn:aws:iam::111122223333:role/example-automation-gateway"
        authentication    = "AWS_IAM"
        policy_engine_key = "access"
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
      isolated = { name = "example_ci" }
    }

    browsers = {
      readonly = { name = "example_readonly_browser" }
    }

    browser_profiles = {
      readonly = { name = "example_readonly_profile" }
    }

    observability = {
      usage = { log_group_name = "/aws/bedrock-agentcore/example/usage" }
    }

    registries = {
      shadow = {
        name = "example_shadow_registry"
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
