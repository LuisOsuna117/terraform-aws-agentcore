# AgentCore Browser submodule

Creates an opt-in AgentCore Browser and any related Browser Profiles. PUBLIC is the default; VPC networking, recordings, certificates, and enterprise policy are explicit inputs.

Use the focused example at [`examples/browser`](../../examples/browser).

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
| [aws_bedrockagentcore_browser.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_browser) | resource |
| [aws_bedrockagentcore_browser_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_browser_profile) | resource |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_browser_signing_enabled"></a> [browser\_signing\_enabled](#input\_browser\_signing\_enabled) | Whether Browser request signing is enabled. | `bool` | `false` | no |
| <a name="input_certificate_secret_arn"></a> [certificate\_secret\_arn](#input\_certificate\_secret\_arn) | Optional Secrets Manager ARN containing a Browser certificate. | `string` | `null` | no |
| <a name="input_create_browser"></a> [create\_browser](#input\_create\_browser) | Whether to create an AgentCore Browser. Disable for profile-only usage. | `bool` | `true` | no |
| <a name="input_description"></a> [description](#input\_description) | Description for the Browser. | `string` | `null` | no |
| <a name="input_enterprise_policy"></a> [enterprise\_policy](#input\_enterprise\_policy) | Optional Browser enterprise policy stored in S3. | <pre>object({<br/>    type       = optional(string)<br/>    bucket     = string<br/>    prefix     = string<br/>    version_id = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_execution_role_arn"></a> [execution\_role\_arn](#input\_execution\_role\_arn) | Optional execution role ARN for the Browser. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name for the Browser and profiles. | `string` | n/a | yes |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | Browser network mode: PUBLIC or VPC. | `string` | `"PUBLIC"` | no |
| <a name="input_profiles"></a> [profiles](#input\_profiles) | Browser Profiles keyed by a stable caller-defined name. | <pre>map(object({<br/>    name        = optional(string)<br/>    description = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_recording"></a> [recording](#input\_recording) | Optional S3 recording configuration. | <pre>object({<br/>    enabled = optional(bool, true)<br/>    bucket  = string<br/>    prefix  = string<br/>  })</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to Browser resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | Security groups used when network\_mode is VPC. | `set(string)` | `[]` | no |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | Subnets used when network\_mode is VPC. | `set(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_browser_arn"></a> [browser\_arn](#output\_browser\_arn) | Browser ARN, or null in profile-only mode. |
| <a name="output_browser_id"></a> [browser\_id](#output\_browser\_id) | Browser ID, or null in profile-only mode. |
| <a name="output_profile_arns"></a> [profile\_arns](#output\_profile\_arns) | Browser Profile ARNs keyed by caller-defined name. |
| <a name="output_profile_ids"></a> [profile\_ids](#output\_profile\_ids) | Browser Profile IDs keyed by caller-defined name. |
<!-- END_TF_DOCS -->
