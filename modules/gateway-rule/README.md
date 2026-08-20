# AgentCore Gateway Rule submodule

Creates one opt-in path/principal Gateway Rule. Static and weighted target routes and Configuration Bundle overrides are mutually exclusive inputs.

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
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_bedrockagentcore_gateway_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_gateway_rule) | resource |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_conditions"></a> [conditions](#input\_conditions) | Optional path or IAM principal conditions. Each entry must configure exactly one matcher; an empty list creates an unconditional rule. | <pre>list(object({<br/>    match_paths = optional(object({<br/>      any_of = list(string)<br/>    }))<br/>    match_principals = optional(object({<br/>      any_of = list(object({<br/>        arn      = string<br/>        operator = optional(string, "StringEquals")<br/>      }))<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_description"></a> [description](#input\_description) | Gateway Rule description. | `string` | `null` | no |
| <a name="input_gateway_identifier"></a> [gateway\_identifier](#input\_gateway\_identifier) | ID of the AgentCore Gateway that owns this rule. | `string` | n/a | yes |
| <a name="input_priority"></a> [priority](#input\_priority) | Rule evaluation priority. | `number` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region in which to manage the Gateway Rule. Defaults to the provider Region. | `string` | `null` | no |
| <a name="input_static_configuration_bundle"></a> [static\_configuration\_bundle](#input\_static\_configuration\_bundle) | Static Configuration Bundle override. Exactly one action input must be configured. | <pre>object({<br/>    bundle_arn     = string<br/>    bundle_version = string<br/>  })</pre> | `null` | no |
| <a name="input_static_target_name"></a> [static\_target\_name](#input\_static\_target\_name) | Static Gateway target name. Exactly one action input must be configured. | `string` | `null` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Optional create, update, and delete timeouts for the Gateway Rule. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_weighted_configuration_bundles"></a> [weighted\_configuration\_bundles](#input\_weighted\_configuration\_bundles) | Weighted Configuration Bundle overrides. Exactly one action input must be configured. | <pre>list(object({<br/>    name           = string<br/>    weight         = number<br/>    bundle_arn     = string<br/>    bundle_version = string<br/>    description    = optional(string)<br/>    metadata       = optional(map(string), {})<br/>  }))</pre> | `[]` | no |
| <a name="input_weighted_targets"></a> [weighted\_targets](#input\_weighted\_targets) | Weighted Gateway target routes. Exactly one action input must be configured. | <pre>list(object({<br/>    name        = string<br/>    target_name = string<br/>    weight      = number<br/>    description = optional(string)<br/>    metadata    = optional(map(string), {})<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway_arn"></a> [gateway\_arn](#output\_gateway\_arn) | ARN of the Gateway that owns this rule. |
| <a name="output_rule_id"></a> [rule\_id](#output\_rule\_id) | Created Gateway Rule ID. |
<!-- END_TF_DOCS -->
