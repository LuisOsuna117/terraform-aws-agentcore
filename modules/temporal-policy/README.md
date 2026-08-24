# AgentCore temporal policy submodule

Creates opt-in Dogwood temporal policies on an existing AgentCore Policy
Engine. This submodule uses the AWS Cloud Control provider because the native
AWS provider does not yet expose the `definition.policy` shape. The safer
default is `LOG_ONLY`; callers must choose `ACTIVE` explicitly after validating
and reviewing the formal policy. Gateway association mode remains the separate
`ENFORCE` control.

```hcl
module "temporal_policy" {
  source = "LuisOsuna117/agentcore/aws//modules/temporal-policy"

  policy_engine_id = module.policy.policy_engine_id
  policies = {
    bounded_calls = {
      statement        = file("bounded-calls.dogwood")
      enforcement_mode = "ACTIVE"
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 1.96, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | >= 1.96, < 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [awscc_bedrockagentcore_policy.this](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/bedrockagentcore_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_policies"></a> [policies](#input\_policies) | Dogwood temporal policies keyed by a stable caller-defined name. Statements are passed through without transformation. | <pre>map(object({<br/>    name             = optional(string)<br/>    description      = optional(string)<br/>    statement        = string<br/>    enforcement_mode = optional(string, "LOG_ONLY")<br/>    validation_mode  = optional(string, "FAIL_ON_ANY_FINDINGS")<br/>  }))</pre> | `{}` | no |
| <a name="input_policy_engine_id"></a> [policy\_engine\_id](#input\_policy\_engine\_id) | Identifier of the existing AgentCore Policy Engine that owns these temporal policies. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_arns"></a> [policy\_arns](#output\_policy\_arns) | Temporal Policy ARNs keyed by caller-defined name. |
<!-- END_TF_DOCS -->
