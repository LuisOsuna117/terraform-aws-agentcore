# AgentCore Runtime Endpoint submodule

Creates one opt-in Runtime Endpoint for an existing AgentCore Runtime. It composes directly with the root module's `agent_runtime_id` output.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.61 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.61 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_bedrockagentcore_agent_runtime_endpoint.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_agent_runtime_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_runtime_id"></a> [agent\_runtime\_id](#input\_agent\_runtime\_id) | AgentCore Runtime ID to qualify with this endpoint. | `string` | n/a | yes |
| <a name="input_agent_runtime_version"></a> [agent\_runtime\_version](#input\_agent\_runtime\_version) | Optional Runtime version routed by this endpoint. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Runtime Endpoint description. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Runtime Endpoint name. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the Runtime Endpoint. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agent_runtime_arn"></a> [agent\_runtime\_arn](#output\_agent\_runtime\_arn) | ARN of the Runtime associated with this endpoint. |
| <a name="output_agent_runtime_endpoint_arn"></a> [agent\_runtime\_endpoint\_arn](#output\_agent\_runtime\_endpoint\_arn) | AgentCore Runtime Endpoint ARN. |
<!-- END_TF_DOCS -->
