resource "aws_bedrockagentcore_agent_runtime" "this" {
  agent_runtime_name = var.runtime_name
  description        = var.description
  role_arn           = var.execution_role_arn

  agent_runtime_artifact {
    container_configuration {
      container_uri = var.image_uri
    }
  }

  network_configuration {
    network_mode = var.network_mode

    dynamic "network_mode_config" {
      for_each = var.network_mode == "VPC" ? [1] : []
      content {
        security_groups = var.vpc_security_group_ids
        subnets         = var.vpc_subnet_ids
      }
    }
  }

  dynamic "authorizer_configuration" {
    for_each = var.authorizer_discovery_url != null ? [1] : []
    content {
      custom_jwt_authorizer {
        discovery_url    = var.authorizer_discovery_url
        allowed_audience = var.authorizer_allowed_audience
        allowed_clients  = var.authorizer_allowed_clients
      }
    }
  }

  dynamic "lifecycle_configuration" {
    for_each = (var.idle_runtime_session_timeout != null || var.max_lifetime != null) ? [1] : []
    content {
      idle_runtime_session_timeout = var.idle_runtime_session_timeout
      max_lifetime                 = var.max_lifetime
    }
  }

  dynamic "protocol_configuration" {
    for_each = var.server_protocol != null ? [1] : []
    content {
      server_protocol = var.server_protocol
    }
  }

  dynamic "request_header_configuration" {
    for_each = length(var.request_header_allowlist) > 0 ? [1] : []
    content {
      request_header_allowlist = var.request_header_allowlist
    }
  }

  environment_variables = var.environment_variables
}
