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
    paths              = ["/operator/*"]
    static_target_name = "operator-runtime"
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_rule.this.action[0].route_to_target[0].static_route[0].target_name == "operator-runtime"
    error_message = "Gateway Rule must preserve its static target route."
  }
}
