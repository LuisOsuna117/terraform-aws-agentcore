# AgentCore Code Interpreter submodule

Creates one opt-in AgentCore Code Interpreter with public, sandbox, or VPC
networking, optional certificate material, tags, Region, and timeouts.

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
| [aws_bedrockagentcore_code_interpreter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_code_interpreter) | resource |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificate_secret_arn"></a> [certificate\_secret\_arn](#input\_certificate\_secret\_arn) | Optional Secrets Manager ARN containing the Code Interpreter certificate. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Human-readable description of the Code Interpreter. | `string` | `"Managed by terraform-aws-agentcore."` | no |
| <a name="input_execution_role_arn"></a> [execution\_role\_arn](#input\_execution\_role\_arn) | ARN of the IAM role assumed by the Code Interpreter. Required for SANDBOX mode. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the AgentCore Code Interpreter. | `string` | n/a | yes |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | Network mode for the Code Interpreter. Valid values: PUBLIC, SANDBOX, VPC. | `string` | `"SANDBOX"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region in which to manage the Code Interpreter. Defaults to the provider Region. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the Code Interpreter. | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Optional create and delete timeouts for the Code Interpreter. | <pre>object({<br/>    create = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | Security group IDs for VPC mode. | `list(string)` | `[]` | no |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | Subnet IDs for VPC mode. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_code_interpreter_arn"></a> [code\_interpreter\_arn](#output\_code\_interpreter\_arn) | ARN of the AgentCore Code Interpreter. |
| <a name="output_code_interpreter_id"></a> [code\_interpreter\_id](#output\_code\_interpreter\_id) | Unique identifier of the AgentCore Code Interpreter. |
| <a name="output_code_interpreter_name"></a> [code\_interpreter\_name](#output\_code\_interpreter\_name) | Resolved name of the AgentCore Code Interpreter. |
| <a name="output_execution_role_arn"></a> [execution\_role\_arn](#output\_execution\_role\_arn) | ARN of the IAM execution role used by the Code Interpreter. |
<!-- END_TF_DOCS -->
