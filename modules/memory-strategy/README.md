# AgentCore Memory Strategy submodule

Adds one built-in or custom strategy to an existing AgentCore Memory. The submodule prefers the current `namespace_templates` API and composes with the root module's `memory_id` output.

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
| [aws_bedrockagentcore_memory_strategy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_memory_strategy) | resource |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_configuration"></a> [custom\_configuration](#input\_custom\_configuration) | Configuration required for CUSTOM strategies and omitted for built-in strategies. | <pre>object({<br/>    type = string<br/>    consolidation = optional(object({<br/>      append_to_prompt = string<br/>      model_id         = string<br/>    }))<br/>    extraction = optional(object({<br/>      append_to_prompt = string<br/>      model_id         = string<br/>    }))<br/>    reflection = optional(object({<br/>      append_to_prompt    = string<br/>      model_id            = string<br/>      namespace_templates = set(string)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Memory Strategy description. | `string` | `null` | no |
| <a name="input_memory_id"></a> [memory\_id](#input\_memory\_id) | ID of the AgentCore Memory to extend. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Memory Strategy name. | `string` | n/a | yes |
| <a name="input_namespace_template"></a> [namespace\_template](#input\_namespace\_template) | Single namespace template for this strategy. | `string` | n/a | yes |
| <a name="input_reflection_namespace_templates"></a> [reflection\_namespace\_templates](#input\_reflection\_namespace\_templates) | Optional reflection namespaces for an EPISODIC strategy. | `set(string)` | `[]` | no |
| <a name="input_type"></a> [type](#input\_type) | Memory Strategy type. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_memory_strategy_id"></a> [memory\_strategy\_id](#output\_memory\_strategy\_id) | Created Memory Strategy ID. |
<!-- END_TF_DOCS -->
