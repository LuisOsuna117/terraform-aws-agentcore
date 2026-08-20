# AgentCore Gateway submodule

Creates one general AgentCore Gateway and a map of native Gateway Targets.
Authorization, Policy Engine enforcement, outbound credentials, target-specific
IAM, streaming, and private connectivity are explicit inputs.

Use the focused examples under [`examples/gateway-only`](../../examples/gateway-only),
[`examples/gateway-target`](../../examples/gateway-target), and
[`examples/gateway-runtime-target`](../../examples/gateway-runtime-target).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.61, < 7.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.12.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.61, < 7.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.12.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_target"></a> [target](#module\_target) | ../gateway-target | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_bedrockagentcore_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_gateway) | resource |
| [aws_iam_role.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.gateway_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [time_sleep.gateway_role_policy_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_authorizer_configuration"></a> [authorizer\_configuration](#input\_authorizer\_configuration) | JWT authorizer configuration. Required when authorizer\_type = "CUSTOM\_JWT".<br/>Shape:<br/>  {<br/>    discovery\_url            = string<br/>    allowed\_audience         = optional(set(string))<br/>    allowed\_clients          = optional(set(string))<br/>    allowed\_scopes           = optional(set(string))<br/>    workload\_identities      = optional(list(string))<br/>    hosting\_environment\_arns = optional(list(string))<br/>    custom\_claims            = optional(set(object(...)))<br/>    private\_endpoint         = optional(object(...))<br/>    private\_endpoint\_overrides = optional(list(object(...)))<br/>  } | <pre>object({<br/>    discovery_url            = string<br/>    allowed_audience         = optional(set(string), [])<br/>    allowed_clients          = optional(set(string), [])<br/>    allowed_scopes           = optional(set(string), [])<br/>    workload_identities      = optional(list(string), [])<br/>    hosting_environment_arns = optional(list(string), [])<br/>    custom_claims = optional(set(object({<br/>      inbound_token_claim_name       = string<br/>      inbound_token_claim_value_type = string<br/>      claim_match_operator           = string<br/>      match_value_string             = optional(string)<br/>      match_value_string_list        = optional(set(string))<br/>    })), [])<br/>    private_endpoint = optional(object({<br/>      managed_vpc_resource = optional(object({<br/>        endpoint_ip_address_type = string<br/>        subnet_ids               = set(string)<br/>        vpc_identifier           = string<br/>        routing_domain           = optional(string)<br/>        security_group_ids       = optional(set(string), [])<br/>        tags                     = optional(map(string), {})<br/>      }))<br/>      self_managed_lattice_resource = optional(object({<br/>        resource_configuration_identifier = string<br/>      }))<br/>    }))<br/>    private_endpoint_overrides = optional(list(object({<br/>      domain = string<br/>      private_endpoint = object({<br/>        managed_vpc_resource = optional(object({<br/>          endpoint_ip_address_type = string<br/>          subnet_ids               = set(string)<br/>          vpc_identifier           = string<br/>          routing_domain           = optional(string)<br/>          security_group_ids       = optional(set(string), [])<br/>          tags                     = optional(map(string), {})<br/>        }))<br/>        self_managed_lattice_resource = optional(object({<br/>          resource_configuration_identifier = string<br/>        }))<br/>      })<br/>    })), [])<br/>  })</pre> | `null` | no |
| <a name="input_authorizer_type"></a> [authorizer\_type](#input\_authorizer\_type) | Inbound authorizer: CUSTOM\_JWT, AWS\_IAM, AUTHENTICATE\_ONLY, or NONE. Offloaded authorization modes must be protected by a Policy Engine or downstream authorization. | `string` | `"AWS_IAM"` | no |
| <a name="input_create_role"></a> [create\_role](#input\_create\_role) | When true, creates an IAM role with the minimal trust policy for the gateway. Set to false and supply role\_arn to reuse an existing role. | `bool` | `true` | no |
| <a name="input_description"></a> [description](#input\_description) | Human-readable description of the gateway. | `string` | `null` | no |
| <a name="input_exception_level"></a> [exception\_level](#input\_exception\_level) | Exception detail level exposed via the gateway. AgentCore currently accepts only DEBUG. | `string` | `null` | no |
| <a name="input_interceptor_configurations"></a> [interceptor\_configurations](#input\_interceptor\_configurations) | List of interceptor configurations (min 0, max 2). Each entry shape:<br/>  {<br/>    interception\_points  = list(string)          # "REQUEST" and/or "RESPONSE"<br/>    lambda\_arn           = string                # ARN of the interceptor Lambda<br/>    pass\_request\_headers = optional(bool, false) # Forward request headers to Lambda<br/>  } | <pre>list(object({<br/>    interception_points  = list(string)<br/>    lambda_arn           = string<br/>    pass_request_headers = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of the KMS key used to encrypt gateway data. When null, AWS-managed encryption is used. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the AgentCore Gateway. | `string` | n/a | yes |
| <a name="input_policy_engine_configuration"></a> [policy\_engine\_configuration](#input\_policy\_engine\_configuration) | Optional Policy Engine association for Gateway authorization. | <pre>object({<br/>    arn  = string<br/>    mode = string<br/>  })</pre> | `null` | no |
| <a name="input_protocol_configuration"></a> [protocol\_configuration](#input\_protocol\_configuration) | MCP protocol configuration. Optional.<br/>Shape:<br/>  {<br/>    instructions       = optional(string)       # Instructions for the MCP handler<br/>    search\_type        = optional(string)       # "SEMANTIC" or "HYBRID"<br/>    supported\_versions = optional(list(string)) # e.g. ["2025-03-26"]<br/>  } | <pre>object({<br/>    instructions               = optional(string)<br/>    search_type                = optional(string)<br/>    supported_versions         = optional(set(string), [])<br/>    session_timeout_in_seconds = optional(number)<br/>    enable_response_streaming  = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_protocol_type"></a> [protocol\_type](#input\_protocol\_type) | Optional gateway aggregation protocol. Set to "MCP" for MCP aggregation, or null for general HTTP targets such as AgentCore Runtime agents. When null and an MCP target is configured, the module infers "MCP". | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region in which to manage the Gateway. Defaults to the provider Region. | `string` | `null` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | ARN of an existing IAM role for the gateway. Required when create\_role = false. | `string` | `null` | no |
| <a name="input_role_policy_arns"></a> [role\_policy\_arns](#input\_role\_policy\_arns) | Managed policy ARNs to attach to the module-created Gateway role. Ignored when create\_role is false. | `set(string)` | `[]` | no |
| <a name="input_role_policy_statements"></a> [role\_policy\_statements](#input\_role\_policy\_statements) | Additional least-privilege IAM statements for the module-created Gateway role, for example Smithy services or credential providers. | <pre>list(object({<br/>    sid       = optional(string)<br/>    effect    = optional(string, "Allow")<br/>    actions   = set(string)<br/>    resources = set(string)<br/>    condition = optional(any)<br/>  }))</pre> | `[]` | no |
| <a name="input_runtime_invoke_arns"></a> [runtime\_invoke\_arns](#input\_runtime\_invoke\_arns) | Additional AgentCore Runtime ARNs the module-created Gateway role may invoke. HTTP Runtime target ARNs are inferred automatically. | `set(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to the gateway resource. | `map(string)` | `{}` | no |
| <a name="input_targets"></a> [targets](#input\_targets) | Map of general Gateway Targets. Each entry uses the native target\_configuration, credential, metadata, private endpoint, and timeout shapes. | `any` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Optional create, update, and delete timeouts for the Gateway. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway_arn"></a> [gateway\_arn](#output\_gateway\_arn) | ARN of the AgentCore Gateway. |
| <a name="output_gateway_id"></a> [gateway\_id](#output\_gateway\_id) | Unique identifier of the AgentCore Gateway. |
| <a name="output_gateway_protocol_type"></a> [gateway\_protocol\_type](#output\_gateway\_protocol\_type) | Effective Gateway aggregation protocol. MCP for aggregation gateways, null for general HTTP gateways. |
| <a name="output_gateway_target_ids"></a> [gateway\_target\_ids](#output\_gateway\_target\_ids) | Map of target keys to AgentCore Gateway target IDs. |
| <a name="output_gateway_target_invocation_urls"></a> [gateway\_target\_invocation\_urls](#output\_gateway\_target\_invocation\_urls) | Map of direct HTTP target keys to their path-routed Gateway invocation URLs. |
| <a name="output_gateway_url"></a> [gateway\_url](#output\_gateway\_url) | URL endpoint for the AgentCore Gateway. |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the IAM role used by the gateway. Equals var.role\_arn when create\_role = false. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the module-created Gateway IAM role. Null when create\_role is false. |
| <a name="output_workload_identity_arn"></a> [workload\_identity\_arn](#output\_workload\_identity\_arn) | ARN of the workload identity associated with the gateway. |
<!-- END_TF_DOCS -->
