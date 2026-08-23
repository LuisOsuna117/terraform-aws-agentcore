# AgentCore Policy submodule

Creates an optional AgentCore Policy Engine, Cedar policies, and independent
resource policies. Set `create_policy_engine = false` to manage only resource
policies without creating or supplying a Policy Engine. The submodule does not
generate or reinterpret Cedar or IAM-style JSON; callers retain ownership of
authorization semantics.

Use [`examples/policy`](../../examples/policy) for Cedar policies and
[`examples/resource-policy`](../../examples/resource-policy) for standalone
resource policies.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.61, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.61, < 7.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_bedrockagentcore_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_policy) | resource |
| [aws_bedrockagentcore_policy_engine.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_policy_engine) | resource |
| [aws_bedrockagentcore_resource_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_resource_policy) | resource |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_policy_engine"></a> [create\_policy\_engine](#input\_create\_policy\_engine) | Whether to create a policy engine. Set false for resource-policy-only use or to attach policies to policy\_engine\_id. | `bool` | `true` | no |
| <a name="input_description"></a> [description](#input\_description) | Description for the module-created policy engine. | `string` | `null` | no |
| <a name="input_encryption_key_arn"></a> [encryption\_key\_arn](#input\_encryption\_key\_arn) | Optional customer-managed KMS key ARN for the policy engine. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name for the policy engine and policies. | `string` | n/a | yes |
| <a name="input_policies"></a> [policies](#input\_policies) | Cedar policies keyed by a stable caller-defined name. Statements are passed through without transformation. | <pre>map(object({<br/>    name            = optional(string)<br/>    description     = optional(string)<br/>    cedar_statement = string<br/>    validation_mode = optional(string, "FAIL_ON_ANY_FINDINGS")<br/>  }))</pre> | `{}` | no |
| <a name="input_policy_engine_id"></a> [policy\_engine\_id](#input\_policy\_engine\_id) | Existing policy engine ID. Required when policies are provided and create\_policy\_engine is false. | `string` | `null` | no |
| <a name="input_resource_policies"></a> [resource\_policies](#input\_resource\_policies) | AgentCore resource policies keyed by a stable caller-defined name. Policy JSON is passed through without transformation. | <pre>map(object({<br/>    resource_arn = string<br/>    policy       = string<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the policy engine. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_arns"></a> [policy\_arns](#output\_policy\_arns) | Policy ARNs keyed by caller-defined name. |
| <a name="output_policy_engine_arn"></a> [policy\_engine\_arn](#output\_policy\_engine\_arn) | Created policy engine ARN, or null when an existing engine is used. |
| <a name="output_policy_engine_id"></a> [policy\_engine\_id](#output\_policy\_engine\_id) | Created or caller-supplied policy engine ID. |
<!-- END_TF_DOCS -->
