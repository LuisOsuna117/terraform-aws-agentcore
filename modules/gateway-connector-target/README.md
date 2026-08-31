# AgentCore Gateway connector target submodule

Creates one version-pinned built-in Connector target on an existing AgentCore Gateway. This isolated, opt-in submodule uses the native CloudFormation resource while the AWS Provider does not expose the Connector target shape.

The caller remains responsible for granting the Gateway execution role the connector-specific invocation permissions documented by AWS.

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

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudformation_stack.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_configurations"></a> [configurations](#input\_configurations) | Connector tool configurations passed to AgentCore. | <pre>list(object({<br/>    name             = string<br/>    parameter_values = optional(any, {})<br/>  }))</pre> | n/a | yes |
| <a name="input_connector_id"></a> [connector\_id](#input\_connector\_id) | AgentCore built-in connector identifier, for example web-search. | `string` | n/a | yes |
| <a name="input_connector_version"></a> [connector\_version](#input\_connector\_version) | Pinned connector version. A version is required so provider defaults cannot change behavior silently. | `string` | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | Optional Gateway connector target description. | `string` | `null` | no |
| <a name="input_gateway_identifier"></a> [gateway\_identifier](#input\_gateway\_identifier) | ID of the AgentCore Gateway that owns this connector target. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Gateway connector target name. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region in which to manage the connector target. Defaults to the provider Region. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the CloudFormation stack and its taggable resources. | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Optional create, update, and delete timeouts for the CloudFormation stack. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_connector_id"></a> [connector\_id](#output\_connector\_id) | Configured built-in connector identifier. |
| <a name="output_connector_version"></a> [connector\_version](#output\_connector\_version) | Pinned built-in connector version. |
| <a name="output_gateway_arn"></a> [gateway\_arn](#output\_gateway\_arn) | ARN of the Gateway that owns the connector target. |
| <a name="output_target_id"></a> [target\_id](#output\_target\_id) | Created Gateway connector target ID. |
<!-- END_TF_DOCS -->
