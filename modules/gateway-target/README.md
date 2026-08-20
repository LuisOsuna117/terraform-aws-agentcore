# AgentCore Gateway Target submodule

Creates one native general Gateway Target. `target_configuration` follows the AWS Provider contract directly: choose HTTP Runtime routing or one MCP-backed API Gateway, Lambda, MCP Server, OpenAPI, or Smithy target. Credentials, metadata propagation, private connectivity, Region, and timeouts are independent opt-in inputs.

Use the focused example at [`examples/gateway-target`](../../examples/gateway-target).

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

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_bedrockagentcore_gateway_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_gateway_target) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_credential_provider_configuration"></a> [credential\_provider\_configuration](#input\_credential\_provider\_configuration) | Optional outbound credential configuration. Omit for targets that explicitly support anonymous access. | <pre>object({<br/>    api_key = optional(object({<br/>      provider_arn              = string<br/>      credential_location       = optional(string)<br/>      credential_parameter_name = optional(string)<br/>      credential_prefix         = optional(string)<br/>    }))<br/>    caller_iam_credentials = optional(object({<br/>      service = string<br/>      region  = optional(string)<br/>    }))<br/>    gateway_iam_role = optional(object({<br/>      service = optional(string)<br/>      region  = optional(string)<br/>    }))<br/>    jwt_passthrough = optional(bool, false)<br/>    oauth = optional(object({<br/>      provider_arn       = string<br/>      grant_type         = optional(string)<br/>      scopes             = set(string)<br/>      default_return_url = optional(string)<br/>      custom_parameters  = optional(map(string), {})<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Gateway Target description. | `string` | `null` | no |
| <a name="input_gateway_identifier"></a> [gateway\_identifier](#input\_gateway\_identifier) | ID of the AgentCore Gateway that owns this target. | `string` | n/a | yes |
| <a name="input_metadata_configuration"></a> [metadata\_configuration](#input\_metadata\_configuration) | Optional HTTP header and query parameter propagation configuration. | <pre>object({<br/>    allowed_query_parameters = optional(set(string), [])<br/>    allowed_request_headers  = optional(set(string), [])<br/>    allowed_response_headers = optional(set(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Gateway Target name. | `string` | n/a | yes |
| <a name="input_private_endpoint"></a> [private\_endpoint](#input\_private\_endpoint) | Optional private connectivity through an AWS-managed VPC resource or an existing VPC Lattice resource configuration. | <pre>object({<br/>    managed_vpc_resource = optional(object({<br/>      vpc_identifier           = string<br/>      subnet_ids               = set(string)<br/>      endpoint_ip_address_type = string<br/>      security_group_ids       = optional(set(string), [])<br/>      routing_domain           = optional(string)<br/>      tags                     = optional(map(string), {})<br/>    }))<br/>    self_managed_lattice_resource = optional(object({<br/>      resource_configuration_identifier = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region in which to manage the Gateway Target. Defaults to the provider Region. | `string` | `null` | no |
| <a name="input_target_configuration"></a> [target\_configuration](#input\_target\_configuration) | Target configuration. Set exactly one of http or mcp; MCP supports API Gateway, Lambda, MCP Server, OpenAPI, or Smithy targets. | <pre>object({<br/>    http = optional(object({<br/>      agentcore_runtime = object({<br/>        arn       = string<br/>        qualifier = optional(string)<br/>      })<br/>    }))<br/>    mcp = optional(object({<br/>      api_gateway = optional(object({<br/>        rest_api_id = string<br/>        stage       = string<br/>        api_gateway_tool_configuration = object({<br/>          tool_filter = optional(set(object({<br/>            filter_path = string<br/>            methods     = set(string)<br/>          })), [])<br/>          tool_override = optional(set(object({<br/>            path        = string<br/>            method      = string<br/>            name        = string<br/>            description = optional(string)<br/>          })), [])<br/>        })<br/>      }))<br/>      lambda = optional(object({<br/>        lambda_arn = string<br/>        tool_schema = object({<br/>          inline_payload = optional(object({<br/>            name          = string<br/>            description   = string<br/>            input_schema  = any<br/>            output_schema = optional(any)<br/>          }))<br/>          s3 = optional(object({<br/>            uri                     = optional(string)<br/>            bucket_owner_account_id = optional(string)<br/>          }))<br/>        })<br/>      }))<br/>      mcp_server = optional(object({<br/>        endpoint          = string<br/>        listing_mode      = optional(string)<br/>        resource_priority = optional(number)<br/>        mcp_tool_schema = optional(object({<br/>          inline_payload = optional(object({<br/>            payload = string<br/>          }))<br/>          s3 = optional(object({<br/>            uri                     = string<br/>            bucket_owner_account_id = optional(string)<br/>          }))<br/>        }))<br/>      }))<br/>      open_api_schema = optional(object({<br/>        inline_payload = optional(object({<br/>          payload = string<br/>        }))<br/>        s3 = optional(object({<br/>          uri                     = optional(string)<br/>          bucket_owner_account_id = optional(string)<br/>        }))<br/>      }))<br/>      smithy_model = optional(object({<br/>        inline_payload = optional(object({<br/>          payload = string<br/>        }))<br/>        s3 = optional(object({<br/>          uri                     = optional(string)<br/>          bucket_owner_account_id = optional(string)<br/>        }))<br/>      }))<br/>    }))<br/>  })</pre> | n/a | yes |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Optional create, update, and delete timeout overrides. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_target_id"></a> [target\_id](#output\_target\_id) | Created Gateway Target ID. |
<!-- END_TF_DOCS -->
