# AgentCore Memory submodule

Creates one opt-in AgentCore Memory with indexed keys, Kinesis delivery,
encryption, expiry, tags, Region, and timeouts. Memory strategies remain
independently managed by the `memory-strategy` submodule.

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
| [aws_bedrockagentcore_memory.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_memory) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_description"></a> [description](#input\_description) | Human-readable description of the memory. | `string` | `null` | no |
| <a name="input_encryption_key_arn"></a> [encryption\_key\_arn](#input\_encryption\_key\_arn) | ARN of the KMS key used to encrypt memory data. When null, AWS-managed encryption is used. | `string` | `null` | no |
| <a name="input_event_expiry_duration"></a> [event\_expiry\_duration](#input\_event\_expiry\_duration) | Number of days after which memory events expire. Valid range: 7–365. | `number` | n/a | yes |
| <a name="input_indexed_keys"></a> [indexed\_keys](#input\_indexed\_keys) | Opt-in Memory indexes. | <pre>list(object({<br/>    key  = string<br/>    type = string<br/>  }))</pre> | `[]` | no |
| <a name="input_kinesis_streams"></a> [kinesis\_streams](#input\_kinesis\_streams) | Opt-in Kinesis stream delivery resources. | <pre>list(object({<br/>    data_stream_arn = string<br/>    content_configurations = optional(list(object({<br/>      type  = string<br/>      level = optional(string)<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_memory_execution_role_arn"></a> [memory\_execution\_role\_arn](#input\_memory\_execution\_role\_arn) | ARN of the IAM role the memory service assumes. Required when using custom memory strategies with model processing. When null, the default service role is used. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the AgentCore Memory resource. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region in which to manage Memory. Defaults to the provider Region. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to the memory resource. | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Optional create, update, and delete timeouts for Memory. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_memory_arn"></a> [memory\_arn](#output\_memory\_arn) | ARN of the AgentCore Memory resource. |
| <a name="output_memory_id"></a> [memory\_id](#output\_memory\_id) | Unique identifier of the AgentCore Memory resource. |
| <a name="output_memory_name"></a> [memory\_name](#output\_memory\_name) | Name of the AgentCore Memory resource. |
<!-- END_TF_DOCS -->
