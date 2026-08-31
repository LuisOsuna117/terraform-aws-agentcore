# AgentCore Runtime submodule

Creates one opt-in AgentCore Runtime from either an Amazon ECR container or an
S3 code artifact. JWT authorization, filesystems, networking, protocol,
observability, endpoints, tags, Region, and timeouts are explicit inputs.

Use the focused examples at [`examples/basic`](../../examples/basic),
[`examples/byo-image`](../../examples/byo-image), and
[`examples/runtime-endpoint`](../../examples/runtime-endpoint).

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
| [aws_bedrockagentcore_agent_runtime.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_agent_runtime) | resource |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_authorizer_configuration"></a> [authorizer\_configuration](#input\_authorizer\_configuration) | Optional CUSTOM\_JWT authorizer with scopes, workload restrictions, custom claims, and private issuer connectivity. | <pre>object({<br/>    discovery_url            = string<br/>    allowed_audience         = optional(set(string), [])<br/>    allowed_clients          = optional(set(string), [])<br/>    allowed_scopes           = optional(set(string), [])<br/>    workload_identities      = optional(list(string), [])<br/>    hosting_environment_arns = optional(list(string), [])<br/>    custom_claims = optional(set(object({<br/>      inbound_token_claim_name       = string<br/>      inbound_token_claim_value_type = string<br/>      claim_match_operator           = string<br/>      match_value_string             = optional(string)<br/>      match_value_string_list        = optional(set(string))<br/>    })), [])<br/>    private_endpoint = optional(object({<br/>      managed_vpc_resource = optional(object({<br/>        endpoint_ip_address_type = string<br/>        subnet_ids               = set(string)<br/>        vpc_identifier           = string<br/>        routing_domain           = optional(string)<br/>        security_group_ids       = optional(set(string), [])<br/>        tags                     = optional(map(string), {})<br/>      }))<br/>      self_managed_lattice_resource = optional(object({<br/>        resource_configuration_identifier = string<br/>      }))<br/>    }))<br/>    private_endpoint_overrides = optional(list(object({<br/>      domain = string<br/>      private_endpoint = object({<br/>        managed_vpc_resource = optional(object({<br/>          endpoint_ip_address_type = string<br/>          subnet_ids               = set(string)<br/>          vpc_identifier           = string<br/>          routing_domain           = optional(string)<br/>          security_group_ids       = optional(set(string), [])<br/>          tags                     = optional(map(string), {})<br/>        }))<br/>        self_managed_lattice_resource = optional(object({<br/>          resource_configuration_identifier = string<br/>        }))<br/>      })<br/>    })), [])<br/>  })</pre> | `null` | no |
| <a name="input_code_configuration"></a> [code\_configuration](#input\_code\_configuration) | Optional direct code artifact stored in S3. Exactly one of image\_uri or code\_configuration must be set. | <pre>object({<br/>    entry_point = list(string)<br/>    runtime     = string<br/>    s3 = object({<br/>      bucket     = string<br/>      prefix     = string<br/>      version_id = optional(string)<br/>    })<br/>  })</pre> | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Human-readable description of the runtime. | `string` | `"Managed by terraform-aws-agentcore."` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables injected into the runtime process. | `map(string)` | `{}` | no |
| <a name="input_execution_role_arn"></a> [execution\_role\_arn](#input\_execution\_role\_arn) | ARN of the IAM execution role the runtime assumes. | `string` | n/a | yes |
| <a name="input_filesystems"></a> [filesystems](#input\_filesystems) | Opt-in Runtime filesystem mounts. Each entry configures exactly one session, S3 Files, or EFS mount. | <pre>list(object({<br/>    session_storage = optional(object({<br/>      mount_path = string<br/>    }))<br/>    s3_files_access_point = optional(object({<br/>      access_point_arn = string<br/>      mount_path       = string<br/>    }))<br/>    efs_access_point = optional(object({<br/>      access_point_arn = string<br/>      mount_path       = string<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_idle_runtime_session_timeout"></a> [idle\_runtime\_session\_timeout](#input\_idle\_runtime\_session\_timeout) | Idle session timeout in seconds. When null, the service default applies. | `number` | `null` | no |
| <a name="input_image_uri"></a> [image\_uri](#input\_image\_uri) | ECR container image URI (including a tag or digest). Exactly one of image\_uri or code\_configuration must be set. | `string` | `null` | no |
| <a name="input_max_lifetime"></a> [max\_lifetime](#input\_max\_lifetime) | Maximum instance lifetime in seconds. When null, the service default applies. | `number` | `null` | no |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | Network mode for the AgentCore runtime. Valid values: PUBLIC, VPC. | `string` | `"PUBLIC"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region in which to manage the Runtime. Defaults to the provider Region. | `string` | `null` | no |
| <a name="input_request_header_allowlist"></a> [request\_header\_allowlist](#input\_request\_header\_allowlist) | List of HTTP request headers to pass through to the runtime. When empty, no additional headers are forwarded. | `list(string)` | `[]` | no |
| <a name="input_runtime_name"></a> [runtime\_name](#input\_runtime\_name) | Resolved name for the AgentCore runtime (hyphens already converted to underscores). | `string` | n/a | yes |
| <a name="input_server_protocol"></a> [server\_protocol](#input\_server\_protocol) | Server protocol for the runtime. Valid values: HTTP, MCP, A2A, AGUI. When null, the service default (HTTP) applies. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the Runtime. | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Optional create, update, and delete timeouts for the Runtime. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | Security group IDs for VPC mode. Required when network\_mode = "VPC". | `list(string)` | `[]` | no |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | Subnet IDs for VPC mode. Required when network\_mode = "VPC". | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agent_runtime_arn"></a> [agent\_runtime\_arn](#output\_agent\_runtime\_arn) | ARN of the AgentCore runtime. |
| <a name="output_agent_runtime_id"></a> [agent\_runtime\_id](#output\_agent\_runtime\_id) | ID of the AgentCore runtime resource. |
| <a name="output_agent_runtime_name"></a> [agent\_runtime\_name](#output\_agent\_runtime\_name) | Resolved name of the AgentCore runtime. |
| <a name="output_agent_runtime_version"></a> [agent\_runtime\_version](#output\_agent\_runtime\_version) | Version identifier of the deployed AgentCore runtime. |
| <a name="output_workload_identity_arn"></a> [workload\_identity\_arn](#output\_workload\_identity\_arn) | Workload identity ARN for the runtime. Use this to grant callers permission to invoke the runtime via AgentCore workload tokens. |
<!-- END_TF_DOCS -->
