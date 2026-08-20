mock_provider "aws" {}

run "runtime_endpoint" {
  command = plan

  module {
    source = "./modules/runtime-endpoint"
  }

  variables {
    agent_runtime_id = "ExampleRuntime-abcdefghij"
    name             = "stable"
  }

  assert {
    condition     = aws_bedrockagentcore_agent_runtime_endpoint.this.agent_runtime_id == "ExampleRuntime-abcdefghij"
    error_message = "Runtime Endpoint must preserve the caller-supplied Runtime ID."
  }
}

run "built_in_memory_strategy" {
  command = plan

  module {
    source = "./modules/memory-strategy"
  }

  variables {
    memory_id          = "MemoryExample-abcdefghij"
    name               = "semantic"
    type               = "SEMANTIC"
    namespace_template = "/actors/{actorId}"
  }

  assert {
    condition     = aws_bedrockagentcore_memory_strategy.this.type == "SEMANTIC"
    error_message = "Built-in Memory Strategy types must pass through unchanged."
  }
}

run "static_gateway_rule" {
  command = plan

  module {
    source = "./modules/gateway-rule"
  }

  variables {
    gateway_identifier = "gateway-abcdefghij"
    priority           = 100
    conditions = [{
      match_paths = {
        any_of = ["/operator/*"]
      }
    }]
    static_target_name = "operator-runtime"
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_rule.this.action[0].route_to_target[0].static_route[0].target_name == "operator-runtime"
    error_message = "Gateway Rule must preserve its static target route."
  }
}

run "principal_only_gateway_rule" {
  command = plan

  module {
    source = "./modules/gateway-rule"
  }

  variables {
    gateway_identifier = "gateway-abcdefghij"
    priority           = 200
    conditions = [{
      match_principals = {
        any_of = [{
          arn      = "arn:aws:iam::123456789012:role/NetworkOperator"
          operator = "StringEquals"
        }]
      }
    }]
    static_target_name = "network-runtime"
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_rule.this.condition[0].match_principals[0].any_of[0].iam_principal[0].operator == "StringEquals"
    error_message = "Gateway Rule must support principal-only conditions and preserve the IAM comparison operator."
  }
}

run "unconditional_gateway_rule" {
  command = plan

  module {
    source = "./modules/gateway-rule"
  }

  variables {
    gateway_identifier = "gateway-abcdefghij"
    priority           = 300
    conditions         = []
    static_target_name = "fallback-runtime"
  }

  assert {
    condition     = length(aws_bedrockagentcore_gateway_rule.this.condition) == 0
    error_message = "Gateway Rule must allow an unconditional fallback rule."
  }
}
