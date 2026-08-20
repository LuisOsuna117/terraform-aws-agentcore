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
      condition     = !contains(var.allowed_tools, "*")
      error_message = "allowed_tools must enumerate tool names; wildcard access is intentionally unsupported by this module."
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
    bedrock_model_config {
      model_id    = var.model_id
      max_tokens  = var.max_tokens
      temperature = var.temperature
      top_p       = var.top_p
    }
  }

  system_prompt {
    text = var.system_prompt
  }

  memory {
    dynamic "disabled" {
      for_each = var.memory == null ? [1] : []
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
  }

  dynamic "skill" {
    for_each = var.skills
    content {
      path = skill.value
    }
  }

  depends_on = [terraform_data.validations]
}
