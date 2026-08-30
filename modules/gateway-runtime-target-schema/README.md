# AgentCore Gateway Runtime schema submodule

Creates one HTTP Runtime Gateway target with an inline or S3 API schema through an isolated CloudFormation stack. This closes the temporary AWS Provider gap without changing schema-less native Gateway targets.

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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_credential_provider_configuration"></a> [credential\_provider\_configuration](#input\_credential\_provider\_configuration) | Optional outbound credential configuration for the Runtime target. | <pre>object({<br/>    api_key = optional(object({<br/>      provider_arn              = string<br/>      credential_location       = optional(string)<br/>      credential_parameter_name = optional(string)<br/>      credential_prefix         = optional(string)<br/>    }))<br/>    caller_iam_credentials = optional(object({<br/>      service = string<br/>      region  = optional(string)<br/>    }))<br/>    gateway_iam_role = optional(object({<br/>      service = optional(string)<br/>      region  = optional(string)<br/>    }))<br/>    jwt_passthrough = optional(bool, false)<br/>    oauth = optional(object({<br/>      provider_arn       = string<br/>      grant_type         = optional(string)<br/>      scopes             = set(string)<br/>      default_return_url = optional(string)<br/>      custom_parameters  = optional(map(string), {})<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Optional Gateway Runtime target description. | `string` | `null` | no |
| <a name="input_gateway_identifier"></a> [gateway\_identifier](#input\_gateway\_identifier) | ID of the AgentCore Gateway that owns the Runtime target. | `string` | n/a | yes |
| <a name="input_metadata_configuration"></a> [metadata\_configuration](#input\_metadata\_configuration) | Optional HTTP header and query parameter propagation configuration. | <pre>object({<br/>    allowed_query_parameters = optional(set(string), [])<br/>    allowed_request_headers  = optional(set(string), [])<br/>    allowed_response_headers = optional(set(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Gateway Runtime target name. | `string` | n/a | yes |
| <a name="input_private_endpoint"></a> [private\_endpoint](#input\_private\_endpoint) | Optional private connectivity configuration. | <pre>object({<br/>    managed_vpc_resource = optional(object({<br/>      vpc_identifier           = string<br/>      subnet_ids               = set(string)<br/>      endpoint_ip_address_type = string<br/>      security_group_ids       = optional(set(string), [])<br/>      routing_domain           = optional(string)<br/>      tags                     = optional(map(string), {})<br/>    }))<br/>    self_managed_lattice_resource = optional(object({<br/>      resource_configuration_identifier = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_qualifier"></a> [qualifier](#input\_qualifier) | Runtime endpoint qualifier. | `string` | `"DEFAULT"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region in which to manage the Runtime target. Defaults to the provider Region. | `string` | `null` | no |
| <a name="input_runtime_arn"></a> [runtime\_arn](#input\_runtime\_arn) | ARN of the AgentCore Runtime behind the target. | `string` | n/a | yes |
| <a name="input_schema"></a> [schema](#input\_schema) | HTTP Runtime API schema source. Set exactly one of inline\_payload or s3. | <pre>object({<br/>    inline_payload = optional(object({<br/>      payload = string<br/>    }))<br/>    s3 = optional(object({<br/>      uri                     = string<br/>      bucket_owner_account_id = optional(string)<br/>    }))<br/>  })</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the CloudFormation stack. | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Optional create, update, and delete timeout overrides. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway_arn"></a> [gateway\_arn](#output\_gateway\_arn) | ARN of the Gateway that owns the Runtime target. |
| <a name="output_target_id"></a> [target\_id](#output\_target\_id) | Created Gateway Runtime target ID. |
<!-- END_TF_DOCS -->
