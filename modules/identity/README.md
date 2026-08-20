# AgentCore Identity submodule

Creates opt-in AgentCore workload identities, API-key credential providers, OAuth2 credential providers, and token-vault KMS configuration.

This submodule requires Terraform or OpenTofu 1.11+ because it only accepts the AWS provider's write-only credential arguments. It never exposes credential values as outputs.

Use the focused example at [`examples/identity`](../../examples/identity).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.61 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.61 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_bedrockagentcore_api_key_credential_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_api_key_credential_provider) | resource |
| [aws_bedrockagentcore_oauth2_credential_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_oauth2_credential_provider) | resource |
| [aws_bedrockagentcore_token_vault_cmk.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_token_vault_cmk) | resource |
| [aws_bedrockagentcore_workload_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_workload_identity) | resource |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_key_credential_providers"></a> [api\_key\_credential\_providers](#input\_api\_key\_credential\_providers) | API key credential provider metadata. Matching secrets are supplied separately through api\_key\_values. | <pre>map(object({<br/>    name           = optional(string)<br/>    secret_version = number<br/>  }))</pre> | `{}` | no |
| <a name="input_api_key_values"></a> [api\_key\_values](#input\_api\_key\_values) | Write-only API keys keyed exactly like api\_key\_credential\_providers. Values are not persisted in state by the AWS provider. | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name used for Identity resources when an item does not provide its own name. | `string` | n/a | yes |
| <a name="input_oauth2_client_ids"></a> [oauth2\_client\_ids](#input\_oauth2\_client\_ids) | Write-only OAuth2 client IDs keyed exactly like oauth2\_credential\_providers. | `map(string)` | `{}` | no |
| <a name="input_oauth2_client_secrets"></a> [oauth2\_client\_secrets](#input\_oauth2\_client\_secrets) | Write-only OAuth2 client secrets keyed exactly like oauth2\_credential\_providers. | `map(string)` | `{}` | no |
| <a name="input_oauth2_credential_providers"></a> [oauth2\_credential\_providers](#input\_oauth2\_credential\_providers) | OAuth2 credential provider metadata. Matching credentials are supplied separately through oauth2\_client\_ids and oauth2\_client\_secrets. | <pre>map(object({<br/>    name                   = optional(string)<br/>    vendor                 = string<br/>    credentials_version    = number<br/>    discovery_url          = optional(string)<br/>    issuer                 = optional(string)<br/>    authorization_endpoint = optional(string)<br/>    token_endpoint         = optional(string)<br/>    response_types         = optional(set(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to taggable Identity resources. | `map(string)` | `{}` | no |
| <a name="input_token_vault_cmk"></a> [token\_vault\_cmk](#input\_token\_vault\_cmk) | Optional token-vault KMS configuration. CustomerManagedKey requires kms\_key\_arn; ServiceManagedKey does not. | <pre>object({<br/>    token_vault_id = optional(string, "default")<br/>    key_type       = string<br/>    kms_key_arn    = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_workload_identities"></a> [workload\_identities](#input\_workload\_identities) | Workload identities keyed by a stable caller-defined name. | <pre>map(object({<br/>    name                      = optional(string)<br/>    allowed_oauth_return_urls = optional(set(string), [])<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_key_credential_provider_arns"></a> [api\_key\_credential\_provider\_arns](#output\_api\_key\_credential\_provider\_arns) | API key credential provider ARNs keyed by caller-defined name. Secret values are never returned. |
| <a name="output_oauth2_credential_provider_arns"></a> [oauth2\_credential\_provider\_arns](#output\_oauth2\_credential\_provider\_arns) | OAuth2 credential provider ARNs keyed by caller-defined name. Client credentials are never returned. |
| <a name="output_token_vault_id"></a> [token\_vault\_id](#output\_token\_vault\_id) | Configured token vault ID, or null when token\_vault\_cmk is not set. |
| <a name="output_workload_identity_arns"></a> [workload\_identity\_arns](#output\_workload\_identity\_arns) | Workload identity ARNs keyed by caller-defined name. |
<!-- END_TF_DOCS -->
