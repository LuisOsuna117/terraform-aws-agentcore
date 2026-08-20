output "runtimes" {
  description = "Runtime IDs, ARNs, versions, and workload identities keyed by caller key."
  value = {
    for key, runtime in aws_bedrockagentcore_agent_runtime.this : key => {
      id                    = runtime.agent_runtime_id
      arn                   = runtime.agent_runtime_arn
      name                  = runtime.agent_runtime_name
      version               = runtime.agent_runtime_version
      workload_identity_arn = try(runtime.workload_identity_details[0].workload_identity_arn, null)
    }
  }
}

output "runtime_endpoints" {
  value = { for key, endpoint in aws_bedrockagentcore_agent_runtime_endpoint.this : key => {
    arn = endpoint.agent_runtime_endpoint_arn
  } }
}

output "gateways" {
  description = "Gateway identifiers and invocation URLs keyed by caller key."
  value = {
    for key, gateway in aws_bedrockagentcore_gateway.this : key => {
      id                    = gateway.gateway_id
      arn                   = gateway.gateway_arn
      url                   = gateway.gateway_url
      workload_identity_arn = try(gateway.workload_identity_details[0].workload_identity_arn, null)
    }
  }
}

output "gateway_targets" {
  value = { for key, target in aws_bedrockagentcore_gateway_target.this : key => target.target_id }
}

output "gateway_rules" {
  value = { for key, rule in aws_bedrockagentcore_gateway_rule.this : key => rule.rule_id }
}

output "gateway_discovery_parameters" {
  value = { for key, parameter in aws_ssm_parameter.gateway_discovery : key => {
    name = parameter.name
    arn  = parameter.arn
  } }
}

output "workload_identities" {
  value = { for key, identity in aws_bedrockagentcore_workload_identity.this : key => identity.workload_identity_arn }
}

output "api_key_credential_providers" {
  value     = { for key, provider in aws_bedrockagentcore_api_key_credential_provider.this : key => provider.credential_provider_arn }
  sensitive = true
}

output "oauth2_credential_providers" {
  value     = { for key, provider in aws_bedrockagentcore_oauth2_credential_provider.this : key => provider.credential_provider_arn }
  sensitive = true
}

output "policy_engines" {
  value = { for key, engine in aws_bedrockagentcore_policy_engine.this : key => {
    id  = engine.policy_engine_id
    arn = engine.policy_engine_arn
  } }
}

output "policies" {
  value = { for key, policy in aws_bedrockagentcore_policy.this : key => {
    id  = policy.policy_id
    arn = policy.policy_arn
  } }
}

output "memories" {
  value = { for key, memory in aws_bedrockagentcore_memory.this : key => {
    id  = memory.id
    arn = memory.arn
  } }
}

output "memory_strategies" {
  value = { for key, strategy in aws_bedrockagentcore_memory_strategy.this : key => strategy.memory_strategy_id }
}

output "browsers" {
  value = { for key, browser in aws_bedrockagentcore_browser.this : key => {
    id  = browser.browser_id
    arn = browser.browser_arn
  } }
}

output "browser_profiles" {
  value = { for key, profile in aws_bedrockagentcore_browser_profile.this : key => {
    id  = profile.profile_id
    arn = profile.profile_arn
  } }
}

output "code_interpreters" {
  value = { for key, interpreter in aws_bedrockagentcore_code_interpreter.this : key => {
    id  = interpreter.code_interpreter_id
    arn = interpreter.code_interpreter_arn
  } }
}

output "harnesses" {
  value = { for key, harness in aws_bedrockagentcore_harness.this : key => {
    id  = harness.harness_id
    arn = harness.arn
  } }
}

output "evaluators" {
  value = { for key, evaluator in aws_bedrockagentcore_evaluator.this : key => {
    id  = evaluator.evaluator_id
    arn = evaluator.evaluator_arn
  } }
}

output "online_evaluations" {
  value = { for key, evaluation in aws_bedrockagentcore_online_evaluation_config.this : key => {
    id  = evaluation.online_evaluation_config_id
    arn = evaluation.online_evaluation_config_arn
  } }
}

output "registries" {
  value = { for key, registry in module.agent_registry_preview : key => {
    id  = registry.registry_id
    arn = registry.registry_arn
  } }
}

output "observability_log_groups" {
  value = { for key, log_group in aws_cloudwatch_log_group.observability : key => log_group.arn }
}

output "preview_stacks" {
  value = { for key, stack in module.preview : key => {
    id      = stack.stack_id
    outputs = stack.outputs
  } }
}
