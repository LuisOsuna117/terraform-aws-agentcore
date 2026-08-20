locals {
  runtime_role_policy_statements = local.create ? {
    for policy_key, policy in var.runtime_role_permissions : policy_key => [
      for statement in policy.statements : {
        Sid    = statement.sid
        Effect = "Allow"
        Action = sort(tolist(statement.actions))
        Resource = sort(distinct(concat(
          tolist(statement.resources),
          [for key in statement.gateway_keys : aws_bedrockagentcore_gateway.this[key].gateway_arn],
          [for key in statement.memory_keys : aws_bedrockagentcore_memory.this[key].arn],
          [for key in statement.code_interpreter_keys : aws_bedrockagentcore_code_interpreter.this[key].code_interpreter_arn],
          [for key in statement.browser_keys : aws_bedrockagentcore_browser.this[key].browser_arn],
          [for key in statement.gateway_parameter_keys : aws_ssm_parameter.gateway_discovery[key].arn],
        )))
      }
    ]
  } : {}
  gateway_role_policy_statements = local.create ? {
    for policy_key, policy in var.gateway_role_permissions : policy_key => [
      for statement in policy.statements : {
        Sid    = statement.sid
        Effect = "Allow"
        Action = sort(tolist(statement.actions))
        Resource = sort(distinct(concat(
          tolist(statement.resources),
          [for key in statement.runtime_keys : aws_bedrockagentcore_agent_runtime.this[key].agent_runtime_arn],
          [for key in statement.api_key_provider_keys : aws_bedrockagentcore_api_key_credential_provider.this[key].credential_provider_arn],
          [for key in statement.oauth2_credential_keys : aws_bedrockagentcore_oauth2_credential_provider.this[key].credential_provider_arn],
          [for key in statement.workload_identity_keys : aws_bedrockagentcore_workload_identity.this[key].workload_identity_arn],
        )))
      }
    ]
  } : {}
}

resource "aws_iam_role_policy" "runtime" {
  for_each = local.create ? var.runtime_role_permissions : {}

  name = "agentcore-runtime-${each.key}"
  role = element(reverse(split("/", var.runtimes[each.value.runtime_key].role_arn)), 0)
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.runtime_role_policy_statements[each.key]
  })
}

resource "aws_iam_role_policy" "gateway" {
  for_each = local.create ? var.gateway_role_permissions : {}

  name = "agentcore-gateway-${each.key}"
  role = element(reverse(split("/", var.gateways[each.value.gateway_key].role_arn)), 0)
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.gateway_role_policy_statements[each.key]
  })
}
