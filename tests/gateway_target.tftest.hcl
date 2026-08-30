mock_provider "aws" {}

run "http_runtime_target_uses_general_configuration" {
  command = plan

  module {
    source = "./modules/gateway-target"
  }

  variables {
    gateway_identifier = "gateway-abcdefghij"
    name               = "operator-runtime"

    target_configuration = {
      http = {
        agentcore_runtime = {
          arn       = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/Operator-abcdefghij"
          qualifier = "LIVE"
          schema = {
            inline_payload = {
              payload = jsonencode({
                openapi = "3.0.3"
                info    = { title = "Operator Runtime", version = "1.0.0" }
                paths   = {}
              })
            }
          }
        }
      }
    }

    credential_provider_configuration = {
      jwt_passthrough = true
    }

    metadata_configuration = {
      allowed_request_headers = ["x-correlation-id"]
    }
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.this.target_configuration[0].http[0].agentcore_runtime[0].qualifier == "LIVE"
    error_message = "HTTP Runtime targets must preserve their Runtime qualifier."
  }

  assert {
    condition     = strcontains(aws_bedrockagentcore_gateway_target.this.target_configuration[0].http[0].agentcore_runtime[0].schema[0].source[0].inline_payload[0].payload, "Operator Runtime")
    error_message = "HTTP Runtime targets must preserve their inline API schema so AgentCore Policy can evaluate request input."
  }

  assert {
    condition     = length(aws_bedrockagentcore_gateway_target.this.credential_provider_configuration[0].jwt_passthrough) == 1
    error_message = "JWT passthrough must be represented by the general credential configuration."
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.this.metadata_configuration[0].allowed_request_headers == toset(["x-correlation-id"])
    error_message = "Configured request headers must be preserved."
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.this.metadata_configuration[0].allowed_query_parameters == null
    error_message = "Omitted query parameters must not be sent to AgentCore as an empty set."
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.this.metadata_configuration[0].allowed_response_headers == null
    error_message = "Omitted response headers must not be sent to AgentCore as an empty set."
  }
}

run "http_runtime_target_rejects_ambiguous_schema_sources" {
  command = plan

  module {
    source = "./modules/gateway-target"
  }

  variables {
    gateway_identifier = "gateway-abcdefghij"
    name               = "ambiguous-runtime"

    target_configuration = {
      http = {
        agentcore_runtime = {
          arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/Operator-abcdefghij"
          schema = {
            inline_payload = {
              payload = jsonencode({ openapi = "3.0.3", paths = {} })
            }
            s3 = {
              uri = "s3://schemas/runtime-openapi.json"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.target_configuration]
}

run "mcp_server_target_supports_schema_and_private_connectivity" {
  command = plan

  module {
    source = "./modules/gateway-target"
  }

  variables {
    gateway_identifier = "gateway-abcdefghij"
    name               = "private-tools"

    target_configuration = {
      mcp = {
        mcp_server = {
          endpoint          = "https://tools.internal.example.com/mcp"
          listing_mode      = "DEFAULT"
          resource_priority = 100
          mcp_tool_schema = {
            inline_payload = {
              payload = jsonencode({ tools = [] })
            }
          }
        }
      }
    }

    private_endpoint = {
      managed_vpc_resource = {
        vpc_identifier           = "vpc-0123456789abcdef0"
        subnet_ids               = ["subnet-0123456789abcdef0"]
        endpoint_ip_address_type = "IPV4"
        security_group_ids       = ["sg-0123456789abcdef0"]
        routing_domain           = "internal.example.com"
        tags                     = { Environment = "test" }
      }
    }
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.this.target_configuration[0].mcp[0].mcp_server[0].resource_priority == 100
    error_message = "MCP Server targets must preserve resource priority."
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.this.private_endpoint[0].managed_vpc_resource[0].vpc_identifier == "vpc-0123456789abcdef0"
    error_message = "Gateway targets must support managed private connectivity."
  }
}

run "api_gateway_target_supports_filters_and_overrides" {
  command = plan

  module {
    source = "./modules/gateway-target"
  }

  variables {
    gateway_identifier = "gateway-abcdefghij"
    name               = "service-api"

    target_configuration = {
      mcp = {
        api_gateway = {
          rest_api_id = "abcdefghij"
          stage       = "v1"
          api_gateway_tool_configuration = {
            tool_filter = [{
              filter_path = "/incidents/*"
              methods     = ["GET", "POST"]
            }]
            tool_override = [{
              path        = "/incidents/{id}"
              method      = "GET"
              name        = "getIncident"
              description = "Get an incident by ID."
            }]
          }
        }
      }
    }

    credential_provider_configuration = {
      gateway_iam_role = {}
    }
  }

  assert {
    condition     = length(aws_bedrockagentcore_gateway_target.this.target_configuration[0].mcp[0].api_gateway[0].api_gateway_tool_configuration[0].tool_filter) == 1
    error_message = "API Gateway targets must render tool filters."
  }

  assert {
    condition     = one(aws_bedrockagentcore_gateway_target.this.target_configuration[0].mcp[0].api_gateway[0].api_gateway_tool_configuration[0].tool_override).name == "getIncident"
    error_message = "API Gateway targets must render tool overrides."
  }
}

run "lambda_target_supports_inline_tool_schema" {
  command = plan

  module {
    source = "./modules/gateway-target"
  }

  variables {
    gateway_identifier = "gateway-abcdefghij"
    name               = "incident-lambda"

    target_configuration = {
      mcp = {
        lambda = {
          lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:incident-tool"
          tool_schema = {
            inline_payload = {
              name        = "get_incident"
              description = "Get an incident."
              input_schema = {
                type = "object"
                property = [
                  {
                    name        = "incident_id"
                    type        = "string"
                    description = "Incident identifier."
                    required    = true
                  },
                  {
                    name = "events"
                    type = "array"
                    items = {
                      type = "object"
                      property = [{
                        name     = "timestamp"
                        type     = "string"
                        required = true
                      }]
                    }
                  },
                ]
              }
              output_schema = {
                type = "object"
                property = [{
                  name     = "status"
                  type     = "string"
                  required = true
                }]
              }
            }
          }
        }
      }
    }

    credential_provider_configuration = {
      gateway_iam_role = {}
    }
  }

  assert {
    condition     = contains([for property in aws_bedrockagentcore_gateway_target.this.target_configuration[0].mcp[0].lambda[0].tool_schema[0].inline_payload[0].input_schema[0].property : property.name], "incident_id")
    error_message = "Lambda targets must render inline input schemas."
  }

  assert {
    condition = one([
      for property in aws_bedrockagentcore_gateway_target.this.target_configuration[0].mcp[0].lambda[0].tool_schema[0].inline_payload[0].input_schema[0].property :
      one(property.items[0].property).name if property.name == "events"
    ]) == "timestamp"
    error_message = "Lambda targets must preserve nested array item schemas."
  }

  assert {
    condition     = one(aws_bedrockagentcore_gateway_target.this.target_configuration[0].mcp[0].lambda[0].tool_schema[0].inline_payload[0].output_schema[0].property).name == "status"
    error_message = "Lambda targets must render inline output schemas."
  }
}

run "openapi_target_supports_s3_source" {
  command = plan

  module {
    source = "./modules/gateway-target"
  }

  variables {
    gateway_identifier = "gateway-abcdefghij"
    name               = "openapi-tools"

    target_configuration = {
      mcp = {
        open_api_schema = {
          s3 = {
            uri                     = "s3://schemas/openapi.json"
            bucket_owner_account_id = "123456789012"
          }
        }
      }
    }

    credential_provider_configuration = {
      oauth = {
        provider_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:token-vault/default/oauth2credentialprovider/provider"
        grant_type   = "CLIENT_CREDENTIALS"
        scopes       = ["tools.read"]
      }
    }
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.this.target_configuration[0].mcp[0].open_api_schema[0].s3[0].uri == "s3://schemas/openapi.json"
    error_message = "OpenAPI targets must support S3 schema sources."
  }
}

run "smithy_target_supports_inline_source_and_self_managed_lattice" {
  command = plan

  module {
    source = "./modules/gateway-target"
  }

  variables {
    gateway_identifier = "gateway-abcdefghij"
    name               = "smithy-tools"

    target_configuration = {
      mcp = {
        smithy_model = {
          inline_payload = {
            payload = "$version: \"2\""
          }
        }
      }
    }

    credential_provider_configuration = {
      caller_iam_credentials = {
        service = "execute-api"
        region  = "us-east-1"
      }
    }

    private_endpoint = {
      self_managed_lattice_resource = {
        resource_configuration_identifier = "rcfg-0123456789abcdef0"
      }
    }
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.this.target_configuration[0].mcp[0].smithy_model[0].inline_payload[0].payload == "$version: \"2\""
    error_message = "Smithy targets must support inline model sources."
  }

  assert {
    condition     = aws_bedrockagentcore_gateway_target.this.private_endpoint[0].self_managed_lattice_resource[0].resource_configuration_identifier == "rcfg-0123456789abcdef0"
    error_message = "Gateway targets must support self-managed VPC Lattice resources."
  }
}
