locals {
  common_tags = merge(
    {
      Module    = "terraform-aws-agentcore"
      ManagedBy = "Terraform"
    },
    var.tags,
  )
}

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition = var.network_mode != "VPC" || (
        length(var.vpc_security_group_ids) > 0 && length(var.vpc_subnet_ids) > 0
      )
      error_message = "VPC Harness mode requires vpc_security_group_ids and vpc_subnet_ids."
    }

    precondition {
      condition     = var.memory == null || var.managed_memory == null
      error_message = "Configure at most one of memory or managed_memory."
    }

  }
}

resource "aws_bedrockagentcore_harness" "this" {
  harness_name          = replace(var.name, "-", "_")
  execution_role_arn    = var.execution_role_arn
  environment_variables = var.environment_variables
  allowed_tools         = var.allowed_tools
  max_iterations        = var.max_iterations
  max_tokens            = var.max_tokens
  timeout_seconds       = var.timeout_seconds
  tags                  = local.common_tags
  truncation = var.truncation == null ? null : [{
    strategy = var.truncation.strategy
    config = var.truncation.config == null ? [] : [{
      sliding_window = var.truncation.config.sliding_window == null ? [] : [{
        messages_count = var.truncation.config.sliding_window.messages_count
      }]
      summarization = var.truncation.config.summarization == null ? [] : [{
        summary_ratio               = var.truncation.config.summarization.summary_ratio
        preserve_recent_messages    = var.truncation.config.summarization.preserve_recent_messages
        summarization_system_prompt = var.truncation.config.summarization.summarization_system_prompt
      }]
    }]
  }]

  dynamic "authorizer_configuration" {
    for_each = var.jwt_authorizer == null ? [] : [var.jwt_authorizer]
    content {
      custom_jwt_authorizer {
        discovery_url    = authorizer_configuration.value.discovery_url
        allowed_audience = authorizer_configuration.value.allowed_audience
        allowed_clients  = authorizer_configuration.value.allowed_clients
        allowed_scopes   = authorizer_configuration.value.allowed_scopes

        dynamic "allowed_workload_configuration" {
          for_each = length(authorizer_configuration.value.workload_identities) + length(authorizer_configuration.value.hosting_environment_arns) == 0 ? [] : [1]
          content {
            workload_identities = authorizer_configuration.value.workload_identities

            dynamic "hosting_environment" {
              for_each = authorizer_configuration.value.hosting_environment_arns
              content {
                arn = hosting_environment.value
              }
            }
          }
        }

        dynamic "custom_claim" {
          for_each = authorizer_configuration.value.custom_claims
          content {
            inbound_token_claim_name       = custom_claim.value.inbound_token_claim_name
            inbound_token_claim_value_type = custom_claim.value.inbound_token_claim_value_type

            authorizing_claim_match_value {
              claim_match_operator = custom_claim.value.claim_match_operator

              claim_match_value {
                match_value_string      = custom_claim.value.match_value_string
                match_value_string_list = custom_claim.value.match_value_string_list
              }
            }
          }
        }

        dynamic "private_endpoint" {
          for_each = authorizer_configuration.value.private_endpoint == null ? [] : [authorizer_configuration.value.private_endpoint]
          content {
            dynamic "managed_vpc_resource" {
              for_each = private_endpoint.value.managed_vpc_resource == null ? [] : [private_endpoint.value.managed_vpc_resource]
              content {
                endpoint_ip_address_type = managed_vpc_resource.value.endpoint_ip_address_type
                subnet_ids               = managed_vpc_resource.value.subnet_ids
                vpc_identifier           = managed_vpc_resource.value.vpc_identifier
                routing_domain           = managed_vpc_resource.value.routing_domain
                security_group_ids       = managed_vpc_resource.value.security_group_ids
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

        dynamic "private_endpoint_overrides" {
          for_each = authorizer_configuration.value.private_endpoint_overrides
          content {
            domain = private_endpoint_overrides.value.domain

            private_endpoint {
              dynamic "managed_vpc_resource" {
                for_each = private_endpoint_overrides.value.private_endpoint.managed_vpc_resource == null ? [] : [private_endpoint_overrides.value.private_endpoint.managed_vpc_resource]
                content {
                  endpoint_ip_address_type = managed_vpc_resource.value.endpoint_ip_address_type
                  subnet_ids               = managed_vpc_resource.value.subnet_ids
                  vpc_identifier           = managed_vpc_resource.value.vpc_identifier
                  routing_domain           = managed_vpc_resource.value.routing_domain
                  security_group_ids       = managed_vpc_resource.value.security_group_ids
                  tags                     = managed_vpc_resource.value.tags
                }
              }

              dynamic "self_managed_lattice_resource" {
                for_each = private_endpoint_overrides.value.private_endpoint.self_managed_lattice_resource == null ? [] : [private_endpoint_overrides.value.private_endpoint.self_managed_lattice_resource]
                content {
                  resource_configuration_identifier = self_managed_lattice_resource.value.resource_configuration_identifier
                }
              }
            }
          }
        }
      }
    }
  }

  environment {
    agentcore_runtime_environment {
      dynamic "lifecycle_configuration" {
        for_each = var.idle_runtime_session_timeout != null || var.max_lifetime != null ? [1] : []
        content {
          idle_runtime_session_timeout = var.idle_runtime_session_timeout
          max_lifetime                 = var.max_lifetime
        }
      }

      dynamic "filesystem_configuration" {
        for_each = var.filesystems
        content {
          dynamic "session_storage" {
            for_each = filesystem_configuration.value.session_storage == null ? [] : [filesystem_configuration.value.session_storage]
            content {
              mount_path = session_storage.value.mount_path
            }
          }

          dynamic "s3_files_access_point" {
            for_each = filesystem_configuration.value.s3_files_access_point == null ? [] : [filesystem_configuration.value.s3_files_access_point]
            content {
              access_point_arn = s3_files_access_point.value.access_point_arn
              mount_path       = s3_files_access_point.value.mount_path
            }
          }

          dynamic "efs_access_point" {
            for_each = filesystem_configuration.value.efs_access_point == null ? [] : [filesystem_configuration.value.efs_access_point]
            content {
              access_point_arn = efs_access_point.value.access_point_arn
              mount_path       = efs_access_point.value.mount_path
            }
          }
        }
      }

      network_configuration {
        network_mode = var.network_mode

        dynamic "network_mode_config" {
          for_each = var.network_mode == "VPC" ? [1] : []
          content {
            security_groups             = var.vpc_security_group_ids
            subnets                     = var.vpc_subnet_ids
            require_service_s3_endpoint = var.require_service_s3_endpoint
          }
        }
      }
    }
  }

  dynamic "environment_artifact" {
    for_each = var.image_uri == null ? [] : [var.image_uri]
    content {
      container_configuration {
        container_uri = environment_artifact.value
      }
    }
  }

  model {
    dynamic "bedrock_model_config" {
      for_each = var.model.bedrock == null ? [] : [var.model.bedrock]
      content {
        model_id    = bedrock_model_config.value.model_id
        max_tokens  = bedrock_model_config.value.max_tokens
        temperature = bedrock_model_config.value.temperature
        top_p       = bedrock_model_config.value.top_p
      }
    }

    dynamic "openai_model_config" {
      for_each = var.model.openai == null ? [] : [var.model.openai]
      content {
        model_id    = openai_model_config.value.model_id
        api_key_arn = openai_model_config.value.api_key_arn
        max_tokens  = openai_model_config.value.max_tokens
        temperature = openai_model_config.value.temperature
        top_p       = openai_model_config.value.top_p
      }
    }

    dynamic "gemini_model_config" {
      for_each = var.model.gemini == null ? [] : [var.model.gemini]
      content {
        model_id    = gemini_model_config.value.model_id
        api_key_arn = gemini_model_config.value.api_key_arn
        max_tokens  = gemini_model_config.value.max_tokens
        temperature = gemini_model_config.value.temperature
        top_p       = gemini_model_config.value.top_p
        top_k       = gemini_model_config.value.top_k
      }
    }
  }

  system_prompt {
    text = var.system_prompt
  }

  memory {
    dynamic "disabled" {
      for_each = var.memory == null && var.managed_memory == null ? [1] : []
      content {}
    }

    dynamic "agentcore_memory_configuration" {
      for_each = var.memory == null ? [] : [var.memory]
      content {
        arn            = agentcore_memory_configuration.value.arn
        actor_id       = agentcore_memory_configuration.value.actor_id
        messages_count = agentcore_memory_configuration.value.messages_count

        dynamic "retrieval_config" {
          for_each = agentcore_memory_configuration.value.retrieval
          content {
            map_block_key   = retrieval_config.key
            relevance_score = retrieval_config.value.relevance_score
            strategy_id     = retrieval_config.value.strategy_id
            top_k           = retrieval_config.value.top_k
          }
        }
      }
    }

    dynamic "managed_memory_configuration" {
      for_each = var.managed_memory == null ? [] : [var.managed_memory]
      content {
        encryption_key_arn    = managed_memory_configuration.value.encryption_key_arn
        event_expiry_duration = managed_memory_configuration.value.event_expiry_duration
        strategies            = managed_memory_configuration.value.strategies
      }
    }
  }

  dynamic "skill" {
    for_each = var.skills
    content {
      path = skill.value
    }
  }

  dynamic "tool" {
    for_each = var.tools
    content {
      type = tool.value.type
      name = tool.value.name

      dynamic "config" {
        for_each = tool.value.config == null ? [] : [tool.value.config]
        content {
          dynamic "remote_mcp" {
            for_each = config.value.remote_mcp == null ? [] : [config.value.remote_mcp]
            content {
              url     = remote_mcp.value.url
              headers = remote_mcp.value.headers
            }
          }

          dynamic "agentcore_browser" {
            for_each = config.value.agentcore_browser == null ? [] : [config.value.agentcore_browser]
            content {
              browser_arn = agentcore_browser.value.browser_arn
            }
          }

          dynamic "agentcore_gateway" {
            for_each = config.value.agentcore_gateway == null ? [] : [config.value.agentcore_gateway]
            content {
              gateway_arn = agentcore_gateway.value.gateway_arn

              dynamic "outbound_auth" {
                for_each = agentcore_gateway.value.outbound_auth == null ? [] : [agentcore_gateway.value.outbound_auth]
                content {
                  aws_iam = outbound_auth.value.aws_iam
                  none    = outbound_auth.value.none

                  dynamic "oauth" {
                    for_each = outbound_auth.value.oauth == null ? [] : [outbound_auth.value.oauth]
                    content {
                      provider_arn       = oauth.value.provider_arn
                      scopes             = oauth.value.scopes
                      custom_parameters  = oauth.value.custom_parameters
                      grant_type         = oauth.value.grant_type
                      default_return_url = oauth.value.default_return_url
                    }
                  }
                }
              }
            }
          }

          dynamic "inline_function" {
            for_each = config.value.inline_function == null ? [] : [config.value.inline_function]
            content {
              description  = inline_function.value.description
              input_schema = inline_function.value.input_schema
            }
          }

          dynamic "agentcore_code_interpreter" {
            for_each = config.value.agentcore_code_interpreter == null ? [] : [config.value.agentcore_code_interpreter]
            content {
              code_interpreter_arn = agentcore_code_interpreter.value.code_interpreter_arn
            }
          }
        }
      }
    }
  }

  depends_on = [terraform_data.validations]
}
