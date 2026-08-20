resource "aws_bedrockagentcore_memory" "this" {
  for_each = var.memories

  name                      = each.value.name
  description               = each.value.description
  event_expiry_duration     = each.value.event_expiry_duration
  encryption_key_arn        = each.value.encryption_key_arn
  memory_execution_role_arn = each.value.memory_execution_role_arn
  tags                      = local.common_tags

  dynamic "indexed_key" {
    for_each = each.value.indexed_keys
    content {
      key  = indexed_key.value.key
      type = indexed_key.value.type
    }
  }
}

resource "aws_bedrockagentcore_memory_strategy" "this" {
  for_each = var.memory_strategies

  memory_id                 = aws_bedrockagentcore_memory.this[each.value.memory_key].id
  name                      = each.value.name
  type                      = each.value.type
  description               = each.value.description
  namespaces                = each.value.namespaces
  namespace_templates       = each.value.namespace_templates
  memory_execution_role_arn = each.value.memory_execution_role_arn
}

resource "aws_bedrockagentcore_browser" "this" {
  for_each = var.browsers

  name               = each.value.name
  description        = each.value.description
  execution_role_arn = each.value.execution_role_arn
  tags               = local.common_tags

  browser_signing {
    enabled = each.value.browser_signing
  }

  network_configuration {
    network_mode = each.value.network_mode
    dynamic "vpc_config" {
      for_each = each.value.network_mode == "VPC" ? [1] : []
      content {
        security_groups = each.value.security_groups
        subnets         = each.value.subnets
      }
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.network_mode != "VPC" || (length(each.value.security_groups) > 0 && length(each.value.subnets) > 0)
      error_message = "VPC Browser requires security_groups and subnets."
    }
  }
}

resource "aws_bedrockagentcore_browser_profile" "this" {
  for_each = var.browser_profiles

  name        = each.value.name
  description = each.value.description
  tags        = local.common_tags
}

resource "aws_bedrockagentcore_code_interpreter" "this" {
  for_each = var.code_interpreters

  name               = each.value.name
  description        = each.value.description
  execution_role_arn = each.value.execution_role_arn
  tags               = local.common_tags

  network_configuration {
    network_mode = each.value.network_mode
    dynamic "vpc_config" {
      for_each = each.value.network_mode == "VPC" ? [1] : []
      content {
        security_groups = each.value.security_groups
        subnets         = each.value.subnets
      }
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.network_mode != "VPC" || (length(each.value.security_groups) > 0 && length(each.value.subnets) > 0)
      error_message = "VPC Code Interpreter requires security_groups and subnets."
    }
  }
}

resource "aws_bedrockagentcore_harness" "this" {
  for_each = var.harnesses

  harness_name          = each.value.name
  execution_role_arn    = each.value.execution_role_arn
  environment_variables = each.value.environment_variables
  allowed_tools         = each.value.allowed_tools
  max_iterations        = each.value.max_iterations
  max_tokens            = each.value.max_tokens
  timeout_seconds       = each.value.timeout_seconds
  tags                  = local.common_tags

  environment {
    agentcore_runtime_environment {
      dynamic "lifecycle_configuration" {
        for_each = each.value.idle_timeout_seconds != null || each.value.max_lifetime_seconds != null ? [1] : []
        content {
          idle_runtime_session_timeout = each.value.idle_timeout_seconds
          max_lifetime                 = each.value.max_lifetime_seconds
        }
      }

      network_configuration {
        network_mode = each.value.network_mode

        dynamic "network_mode_config" {
          for_each = each.value.network_mode == "VPC" ? [1] : []
          content {
            security_groups             = each.value.security_groups
            subnets                     = each.value.subnets
            require_service_s3_endpoint = each.value.require_s3_endpoint
          }
        }
      }
    }
  }

  environment_artifact {
    container_configuration {
      container_uri = each.value.image_uri
    }
  }

  model {
    bedrock_model_config {
      model_id    = each.value.model_id
      max_tokens  = each.value.max_tokens
      temperature = each.value.temperature
      top_p       = each.value.top_p
    }
  }

  system_prompt {
    text = each.value.system_prompt
  }

  memory {
    disabled {}
  }

  lifecycle {
    precondition {
      condition     = contains(["PUBLIC", "VPC"], each.value.network_mode)
      error_message = "Harness network_mode must be PUBLIC or VPC."
    }
    precondition {
      condition     = each.value.network_mode != "VPC" || (length(each.value.security_groups) > 0 && length(each.value.subnets) > 0)
      error_message = "VPC Harness requires security_groups and subnets."
    }
  }
}
