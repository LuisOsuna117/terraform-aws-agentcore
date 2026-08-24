resource "awscc_bedrockagentcore_policy" "this" {
  for_each = var.policies

  name             = replace(coalesce(each.value.name, each.key), "-", "_")
  description      = each.value.description
  policy_engine_id = var.policy_engine_id
  enforcement_mode = each.value.enforcement_mode
  validation_mode  = each.value.validation_mode

  definition = {
    policy = {
      statement = each.value.statement
    }
  }
}
