resource "aws_bedrockagentcore_gateway_target" "this" {
  gateway_identifier = var.gateway_identifier
  name               = var.name
  description        = var.description
  region             = var.region

  dynamic "credential_provider_configuration" {
    for_each = var.credential_provider_configuration == null ? [] : [var.credential_provider_configuration]
    content {
      dynamic "api_key" {
        for_each = credential_provider_configuration.value.api_key == null ? [] : [credential_provider_configuration.value.api_key]
        content {
          provider_arn              = api_key.value.provider_arn
          credential_location       = api_key.value.credential_location
          credential_parameter_name = api_key.value.credential_parameter_name
          credential_prefix         = api_key.value.credential_prefix
        }
      }

      dynamic "caller_iam_credentials" {
        for_each = credential_provider_configuration.value.caller_iam_credentials == null ? [] : [credential_provider_configuration.value.caller_iam_credentials]
        content {
          service = caller_iam_credentials.value.service
          region  = caller_iam_credentials.value.region
        }
      }

      dynamic "gateway_iam_role" {
        for_each = credential_provider_configuration.value.gateway_iam_role == null ? [] : [credential_provider_configuration.value.gateway_iam_role]
        content {
          service = gateway_iam_role.value.service
          region  = gateway_iam_role.value.region
        }
      }

      dynamic "jwt_passthrough" {
        for_each = credential_provider_configuration.value.jwt_passthrough ? [1] : []
        content {}
      }

      dynamic "oauth" {
        for_each = credential_provider_configuration.value.oauth == null ? [] : [credential_provider_configuration.value.oauth]
        content {
          provider_arn       = oauth.value.provider_arn
          grant_type         = oauth.value.grant_type
          scopes             = oauth.value.scopes
          default_return_url = oauth.value.default_return_url
          custom_parameters  = oauth.value.custom_parameters
        }
      }
    }
  }

  target_configuration {
    dynamic "http" {
      for_each = var.target_configuration.http == null ? [] : [var.target_configuration.http]
      content {
        agentcore_runtime {
          arn       = http.value.agentcore_runtime.arn
          qualifier = http.value.agentcore_runtime.qualifier

          dynamic "schema" {
            for_each = http.value.agentcore_runtime.schema == null ? [] : [http.value.agentcore_runtime.schema]
            content {
              source {
                dynamic "inline_payload" {
                  for_each = schema.value.inline_payload == null ? [] : [schema.value.inline_payload]
                  content {
                    payload = inline_payload.value.payload
                  }
                }

                dynamic "s3" {
                  for_each = schema.value.s3 == null ? [] : [schema.value.s3]
                  content {
                    uri                     = s3.value.uri
                    bucket_owner_account_id = s3.value.bucket_owner_account_id
                  }
                }
              }
            }
          }
        }
      }
    }

    dynamic "mcp" {
      for_each = var.target_configuration.mcp == null ? [] : [var.target_configuration.mcp]
      content {
        dynamic "api_gateway" {
          for_each = mcp.value.api_gateway == null ? [] : [mcp.value.api_gateway]
          content {
            rest_api_id = api_gateway.value.rest_api_id
            stage       = api_gateway.value.stage

            api_gateway_tool_configuration {
              dynamic "tool_filter" {
                for_each = api_gateway.value.api_gateway_tool_configuration.tool_filter
                content {
                  filter_path = tool_filter.value.filter_path
                  methods     = tool_filter.value.methods
                }
              }

              dynamic "tool_override" {
                for_each = api_gateway.value.api_gateway_tool_configuration.tool_override
                content {
                  path        = tool_override.value.path
                  method      = tool_override.value.method
                  name        = tool_override.value.name
                  description = tool_override.value.description
                }
              }
            }
          }
        }

        dynamic "lambda" {
          for_each = mcp.value.lambda == null ? [] : [mcp.value.lambda]
          content {
            lambda_arn = lambda.value.lambda_arn

            tool_schema {
              dynamic "inline_payload" {
                for_each = lambda.value.tool_schema.inline_payload == null ? [] : [lambda.value.tool_schema.inline_payload]
                content {
                  name        = inline_payload.value.name
                  description = inline_payload.value.description

                  input_schema {
                    type        = inline_payload.value.input_schema.type
                    description = try(inline_payload.value.input_schema.description, null)

                    dynamic "items" {
                      for_each = try(inline_payload.value.input_schema.items, null) == null ? [] : [inline_payload.value.input_schema.items]
                      content {
                        type        = items.value.type
                        description = try(items.value.description, null)

                        dynamic "items" {
                          for_each = try(items.value.items, null) == null ? [] : [items.value.items]
                          content {
                            type            = items.value.type
                            description     = try(items.value.description, null)
                            items_json      = try(items.value.items_json, null)
                            properties_json = try(items.value.properties_json, null)
                          }
                        }

                        dynamic "property" {
                          for_each = try(items.value.property, [])
                          content {
                            name            = property.value.name
                            type            = property.value.type
                            description     = try(property.value.description, null)
                            required        = try(property.value.required, null)
                            items_json      = try(property.value.items_json, null)
                            properties_json = try(property.value.properties_json, null)
                          }
                        }
                      }
                    }

                    dynamic "property" {
                      for_each = try(inline_payload.value.input_schema.property, [])
                      content {
                        name        = property.value.name
                        type        = property.value.type
                        description = try(property.value.description, null)
                        required    = try(property.value.required, null)

                        dynamic "items" {
                          for_each = try(property.value.items, null) == null ? [] : [property.value.items]
                          content {
                            type        = items.value.type
                            description = try(items.value.description, null)

                            dynamic "items" {
                              for_each = try(items.value.items, null) == null ? [] : [items.value.items]
                              content {
                                type            = items.value.type
                                description     = try(items.value.description, null)
                                items_json      = try(items.value.items_json, null)
                                properties_json = try(items.value.properties_json, null)
                              }
                            }

                            dynamic "property" {
                              for_each = try(items.value.property, [])
                              content {
                                name            = property.value.name
                                type            = property.value.type
                                description     = try(property.value.description, null)
                                required        = try(property.value.required, null)
                                items_json      = try(property.value.items_json, null)
                                properties_json = try(property.value.properties_json, null)
                              }
                            }
                          }
                        }

                        dynamic "property" {
                          for_each = try(property.value.property, [])
                          content {
                            name            = property.value.name
                            type            = property.value.type
                            description     = try(property.value.description, null)
                            required        = try(property.value.required, null)
                            items_json      = try(property.value.items_json, null)
                            properties_json = try(property.value.properties_json, null)
                          }
                        }
                      }
                    }
                  }

                  dynamic "output_schema" {
                    for_each = try(inline_payload.value.output_schema, null) == null ? [] : [inline_payload.value.output_schema]
                    content {
                      type        = output_schema.value.type
                      description = try(output_schema.value.description, null)

                      dynamic "items" {
                        for_each = try(output_schema.value.items, null) == null ? [] : [output_schema.value.items]
                        content {
                          type        = items.value.type
                          description = try(items.value.description, null)

                          dynamic "items" {
                            for_each = try(items.value.items, null) == null ? [] : [items.value.items]
                            content {
                              type            = items.value.type
                              description     = try(items.value.description, null)
                              items_json      = try(items.value.items_json, null)
                              properties_json = try(items.value.properties_json, null)
                            }
                          }

                          dynamic "property" {
                            for_each = try(items.value.property, [])
                            content {
                              name            = property.value.name
                              type            = property.value.type
                              description     = try(property.value.description, null)
                              required        = try(property.value.required, null)
                              items_json      = try(property.value.items_json, null)
                              properties_json = try(property.value.properties_json, null)
                            }
                          }
                        }
                      }

                      dynamic "property" {
                        for_each = try(output_schema.value.property, [])
                        content {
                          name        = property.value.name
                          type        = property.value.type
                          description = try(property.value.description, null)
                          required    = try(property.value.required, null)

                          dynamic "items" {
                            for_each = try(property.value.items, null) == null ? [] : [property.value.items]
                            content {
                              type        = items.value.type
                              description = try(items.value.description, null)

                              dynamic "items" {
                                for_each = try(items.value.items, null) == null ? [] : [items.value.items]
                                content {
                                  type            = items.value.type
                                  description     = try(items.value.description, null)
                                  items_json      = try(items.value.items_json, null)
                                  properties_json = try(items.value.properties_json, null)
                                }
                              }

                              dynamic "property" {
                                for_each = try(items.value.property, [])
                                content {
                                  name            = property.value.name
                                  type            = property.value.type
                                  description     = try(property.value.description, null)
                                  required        = try(property.value.required, null)
                                  items_json      = try(property.value.items_json, null)
                                  properties_json = try(property.value.properties_json, null)
                                }
                              }
                            }
                          }

                          dynamic "property" {
                            for_each = try(property.value.property, [])
                            content {
                              name            = property.value.name
                              type            = property.value.type
                              description     = try(property.value.description, null)
                              required        = try(property.value.required, null)
                              items_json      = try(property.value.items_json, null)
                              properties_json = try(property.value.properties_json, null)
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }

              dynamic "s3" {
                for_each = lambda.value.tool_schema.s3 == null ? [] : [lambda.value.tool_schema.s3]
                content {
                  uri                     = s3.value.uri
                  bucket_owner_account_id = s3.value.bucket_owner_account_id
                }
              }
            }
          }
        }

        dynamic "mcp_server" {
          for_each = mcp.value.mcp_server == null ? [] : [mcp.value.mcp_server]
          content {
            endpoint          = mcp_server.value.endpoint
            listing_mode      = mcp_server.value.listing_mode
            resource_priority = mcp_server.value.resource_priority

            dynamic "mcp_tool_schema" {
              for_each = mcp_server.value.mcp_tool_schema == null ? [] : [mcp_server.value.mcp_tool_schema]
              content {
                dynamic "inline_payload" {
                  for_each = mcp_tool_schema.value.inline_payload == null ? [] : [mcp_tool_schema.value.inline_payload]
                  content {
                    payload = inline_payload.value.payload
                  }
                }

                dynamic "s3" {
                  for_each = mcp_tool_schema.value.s3 == null ? [] : [mcp_tool_schema.value.s3]
                  content {
                    uri                     = s3.value.uri
                    bucket_owner_account_id = s3.value.bucket_owner_account_id
                  }
                }
              }
            }
          }
        }

        dynamic "open_api_schema" {
          for_each = mcp.value.open_api_schema == null ? [] : [mcp.value.open_api_schema]
          content {
            dynamic "inline_payload" {
              for_each = open_api_schema.value.inline_payload == null ? [] : [open_api_schema.value.inline_payload]
              content {
                payload = inline_payload.value.payload
              }
            }

            dynamic "s3" {
              for_each = open_api_schema.value.s3 == null ? [] : [open_api_schema.value.s3]
              content {
                uri                     = s3.value.uri
                bucket_owner_account_id = s3.value.bucket_owner_account_id
              }
            }
          }
        }

        dynamic "smithy_model" {
          for_each = mcp.value.smithy_model == null ? [] : [mcp.value.smithy_model]
          content {
            dynamic "inline_payload" {
              for_each = smithy_model.value.inline_payload == null ? [] : [smithy_model.value.inline_payload]
              content {
                payload = inline_payload.value.payload
              }
            }

            dynamic "s3" {
              for_each = smithy_model.value.s3 == null ? [] : [smithy_model.value.s3]
              content {
                uri                     = s3.value.uri
                bucket_owner_account_id = s3.value.bucket_owner_account_id
              }
            }
          }
        }
      }
    }
  }

  dynamic "metadata_configuration" {
    for_each = var.metadata_configuration == null ? [] : [var.metadata_configuration]
    content {
      allowed_query_parameters = length(metadata_configuration.value.allowed_query_parameters) == 0 ? null : metadata_configuration.value.allowed_query_parameters
      allowed_request_headers  = length(metadata_configuration.value.allowed_request_headers) == 0 ? null : metadata_configuration.value.allowed_request_headers
      allowed_response_headers = length(metadata_configuration.value.allowed_response_headers) == 0 ? null : metadata_configuration.value.allowed_response_headers
    }
  }

  dynamic "private_endpoint" {
    for_each = var.private_endpoint == null ? [] : [var.private_endpoint]
    content {
      dynamic "managed_vpc_resource" {
        for_each = private_endpoint.value.managed_vpc_resource == null ? [] : [private_endpoint.value.managed_vpc_resource]
        content {
          vpc_identifier           = managed_vpc_resource.value.vpc_identifier
          subnet_ids               = managed_vpc_resource.value.subnet_ids
          endpoint_ip_address_type = managed_vpc_resource.value.endpoint_ip_address_type
          security_group_ids       = managed_vpc_resource.value.security_group_ids
          routing_domain           = managed_vpc_resource.value.routing_domain
          tags                     = managed_vpc_resource.value.tags
        }
      }

      dynamic "self_managed_lattice_resource" {
        for_each = private_endpoint.value.self_managed_lattice_resource == null ? [] : [private_endpoint.value.self_managed_lattice_resource]
        content {
          resource_configuration_identifier = self_managed_lattice_resource.value.resource_configuration_identifier
        }
      }
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
