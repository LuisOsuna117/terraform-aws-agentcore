# AgentCore Managed Harness submodule

Creates one Managed Harness with opt-in models, tools, filesystems, truncation, JWT authorization, Memory, network, and execution budgets. No tools are enabled by default.

Use the focused example at [`examples/managed-harness`](../../examples/managed-harness).

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
| [aws_bedrockagentcore_harness.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_harness) | resource |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_tools"></a> [allowed\_tools](#input\_allowed\_tools) | Tool names the Harness may invoke. Defaults to no allowed tools; wildcard access must be explicitly requested with ["*"]. | `list(string)` | `[]` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables for the Harness. Do not place credentials in this map. | `map(string)` | `{}` | no |
| <a name="input_execution_role_arn"></a> [execution\_role\_arn](#input\_execution\_role\_arn) | IAM role assumed by the Managed Harness. | `string` | n/a | yes |
| <a name="input_filesystems"></a> [filesystems](#input\_filesystems) | Opt-in runtime filesystem mounts. Each entry configures exactly one storage type. | <pre>list(object({<br/>    session_storage = optional(object({<br/>      mount_path = string<br/>    }))<br/>    s3_files_access_point = optional(object({<br/>      access_point_arn = string<br/>      mount_path       = string<br/>    }))<br/>    efs_access_point = optional(object({<br/>      access_point_arn = string<br/>      mount_path       = string<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_idle_runtime_session_timeout"></a> [idle\_runtime\_session\_timeout](#input\_idle\_runtime\_session\_timeout) | Optional idle session timeout in seconds. | `number` | `null` | no |
| <a name="input_image_uri"></a> [image\_uri](#input\_image\_uri) | Optional container image URI for a custom Harness environment. | `string` | `null` | no |
| <a name="input_jwt_authorizer"></a> [jwt\_authorizer](#input\_jwt\_authorizer) | Optional CUSTOM\_JWT authorizer configuration. | <pre>object({<br/>    discovery_url            = string<br/>    allowed_audience         = optional(set(string), [])<br/>    allowed_clients          = optional(set(string), [])<br/>    allowed_scopes           = optional(set(string), [])<br/>    workload_identities      = optional(list(string), [])<br/>    hosting_environment_arns = optional(list(string), [])<br/>    custom_claims = optional(set(object({<br/>      inbound_token_claim_name       = string<br/>      inbound_token_claim_value_type = string<br/>      claim_match_operator           = string<br/>      match_value_string             = optional(string)<br/>      match_value_string_list        = optional(set(string))<br/>    })), [])<br/>    private_endpoint = optional(object({<br/>      managed_vpc_resource = optional(object({<br/>        endpoint_ip_address_type = string<br/>        subnet_ids               = set(string)<br/>        vpc_identifier           = string<br/>        routing_domain           = optional(string)<br/>        security_group_ids       = optional(set(string), [])<br/>        tags                     = optional(map(string), {})<br/>      }))<br/>      self_managed_lattice_resource = optional(object({<br/>        resource_configuration_identifier = string<br/>      }))<br/>    }))<br/>    private_endpoint_overrides = optional(list(object({<br/>      domain = string<br/>      private_endpoint = object({<br/>        managed_vpc_resource = optional(object({<br/>          endpoint_ip_address_type = string<br/>          subnet_ids               = set(string)<br/>          vpc_identifier           = string<br/>          routing_domain           = optional(string)<br/>          security_group_ids       = optional(set(string), [])<br/>          tags                     = optional(map(string), {})<br/>        }))<br/>        self_managed_lattice_resource = optional(object({<br/>          resource_configuration_identifier = string<br/>        }))<br/>      })<br/>    })), [])<br/>  })</pre> | `null` | no |
| <a name="input_managed_memory"></a> [managed\_memory](#input\_managed\_memory) | Optional Harness-managed Memory configuration. Cannot be combined with memory. | <pre>object({<br/>    encryption_key_arn    = optional(string)<br/>    event_expiry_duration = optional(number)<br/>    strategies            = optional(set(string))<br/>  })</pre> | `null` | no |
| <a name="input_max_iterations"></a> [max\_iterations](#input\_max\_iterations) | Maximum agent-loop iterations per invocation. | `number` | `10` | no |
| <a name="input_max_lifetime"></a> [max\_lifetime](#input\_max\_lifetime) | Optional maximum environment lifetime in seconds. | `number` | `null` | no |
| <a name="input_max_tokens"></a> [max\_tokens](#input\_max\_tokens) | Maximum model output tokens per iteration. | `number` | `8192` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Optional AgentCore Memory configuration. Memory is disabled when null. | <pre>object({<br/>    arn            = string<br/>    actor_id       = optional(string)<br/>    messages_count = optional(number)<br/>    retrieval = optional(map(object({<br/>      relevance_score = optional(number)<br/>      strategy_id     = optional(string)<br/>      top_k           = optional(number)<br/>    })), {})<br/>  })</pre> | `null` | no |
| <a name="input_model"></a> [model](#input\_model) | Exactly one Managed Harness model configuration. | <pre>object({<br/>    bedrock = optional(object({<br/>      model_id    = string<br/>      max_tokens  = optional(number)<br/>      temperature = optional(number)<br/>      top_p       = optional(number)<br/>    }))<br/>    openai = optional(object({<br/>      model_id    = string<br/>      api_key_arn = string<br/>      max_tokens  = optional(number)<br/>      temperature = optional(number)<br/>      top_p       = optional(number)<br/>    }))<br/>    gemini = optional(object({<br/>      model_id    = string<br/>      api_key_arn = string<br/>      max_tokens  = optional(number)<br/>      temperature = optional(number)<br/>      top_p       = optional(number)<br/>      top_k       = optional(number)<br/>    }))<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Managed Harness name. Hyphens are normalized to underscores. | `string` | n/a | yes |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | Harness network mode: PUBLIC or VPC. | `string` | `"PUBLIC"` | no |
| <a name="input_require_service_s3_endpoint"></a> [require\_service\_s3\_endpoint](#input\_require\_service\_s3\_endpoint) | Whether VPC Harness networking requires an S3 service endpoint. | `bool` | `false` | no |
| <a name="input_skills"></a> [skills](#input\_skills) | Filesystem paths to Harness skill definitions. | `set(string)` | `[]` | no |
| <a name="input_system_prompt"></a> [system\_prompt](#input\_system\_prompt) | Harness system prompt. This value is sensitive in plans and state. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the Harness. | `map(string)` | `{}` | no |
| <a name="input_timeout_seconds"></a> [timeout\_seconds](#input\_timeout\_seconds) | Maximum Harness invocation duration in seconds. | `number` | `900` | no |
| <a name="input_tools"></a> [tools](#input\_tools) | Opt-in Harness tool configurations. Remote MCP headers and inline schemas are sensitive provider attributes. | <pre>list(object({<br/>    type = string<br/>    name = optional(string)<br/>    config = optional(object({<br/>      remote_mcp = optional(object({<br/>        url     = string<br/>        headers = optional(map(string), {})<br/>      }))<br/>      agentcore_browser = optional(object({<br/>        browser_arn = optional(string)<br/>      }))<br/>      agentcore_gateway = optional(object({<br/>        gateway_arn = string<br/>        outbound_auth = optional(object({<br/>          aws_iam = optional(bool)<br/>          none    = optional(bool)<br/>          oauth = optional(object({<br/>            provider_arn       = string<br/>            scopes             = list(string)<br/>            custom_parameters  = optional(map(string), {})<br/>            grant_type         = optional(string)<br/>            default_return_url = optional(string)<br/>          }))<br/>        }))<br/>      }))<br/>      inline_function = optional(object({<br/>        description  = string<br/>        input_schema = string<br/>      }))<br/>      agentcore_code_interpreter = optional(object({<br/>        code_interpreter_arn = optional(string)<br/>      }))<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_truncation"></a> [truncation](#input\_truncation) | Optional conversation truncation strategy and provider-native configuration. | <pre>object({<br/>    strategy = string<br/>    config = optional(object({<br/>      sliding_window = optional(object({<br/>        messages_count = optional(number)<br/>      }))<br/>      summarization = optional(object({<br/>        summary_ratio               = optional(number)<br/>        preserve_recent_messages    = optional(number)<br/>        summarization_system_prompt = optional(string)<br/>      }))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | Security groups used when network\_mode is VPC. | `set(string)` | `[]` | no |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | Subnets used when network\_mode is VPC. | `set(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_harness_arn"></a> [harness\_arn](#output\_harness\_arn) | Managed Harness ARN. |
| <a name="output_harness_id"></a> [harness\_id](#output\_harness\_id) | Managed Harness ID. |
<!-- END_TF_DOCS -->
