data "aws_region" "current" {}

locals {
  # UpdateAgentRuntime requires the artifact, role, and network configuration
  # even when only metadataConfiguration changes. Mirror every runtime setting
  # managed by this submodule so the compatibility update is non-destructive.
  runtime_update_input = merge(
    {
      agentRuntimeId = aws_bedrockagentcore_agent_runtime.this.agent_runtime_id
      agentRuntimeArtifact = {
        containerConfiguration = {
          containerUri = var.image_uri
        }
      }
      description = var.description
      roleArn     = var.execution_role_arn
      networkConfiguration = merge(
        {
          networkMode = var.network_mode
        },
        var.network_mode == "VPC" ? {
          networkModeConfig = {
            securityGroups = var.vpc_security_group_ids
            subnets        = var.vpc_subnet_ids
          }
        } : {},
      )
    },
    var.metadata_configuration != null ? {
      metadataConfiguration = {
        requireMMDSV2 = var.metadata_configuration.require_mmdsv2
      }
    } : {},
    var.authorizer_discovery_url != null ? {
      authorizerConfiguration = {
        customJWTAuthorizer = merge(
          {
            discoveryUrl = var.authorizer_discovery_url
          },
          length(var.authorizer_allowed_audience) > 0 ? { allowedAudience = var.authorizer_allowed_audience } : {},
          length(var.authorizer_allowed_clients) > 0 ? { allowedClients = var.authorizer_allowed_clients } : {},
        )
      }
    } : {},
    var.idle_runtime_session_timeout != null || var.max_lifetime != null ? {
      lifecycleConfiguration = merge(
        var.idle_runtime_session_timeout != null ? { idleRuntimeSessionTimeout = var.idle_runtime_session_timeout } : {},
        var.max_lifetime != null ? { maxLifetime = var.max_lifetime } : {},
      )
    } : {},
    var.server_protocol != null ? {
      protocolConfiguration = {
        serverProtocol = var.server_protocol
      }
    } : {},
    length(var.request_header_allowlist) > 0 ? {
      requestHeaderConfiguration = {
        requestHeaderAllowlist = var.request_header_allowlist
      }
    } : {},
    length(var.environment_variables) > 0 ? {
      environmentVariables = var.environment_variables
    } : {},
  )
}

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

# metadataConfiguration is available in the AgentCore UpdateAgentRuntime API
# but not yet in hashicorp/aws. Keep this temporary bridge isolated so it can
# be replaced by a native metadata_configuration block when provider support
# lands.
resource "local_sensitive_file" "runtime_update_input" {
  count = var.metadata_configuration != null ? 1 : 0

  content         = jsonencode(local.runtime_update_input)
  filename        = "${path.root}/.terraform/agentcore-${aws_bedrockagentcore_agent_runtime.this.agent_runtime_id}-metadata.json"
  file_permission = "0600"
}

resource "terraform_data" "metadata_configuration" {
  count = var.metadata_configuration != null ? 1 : 0

  triggers_replace = [local_sensitive_file.runtime_update_input[0].content_sha256]

  provisioner "local-exec" {
    command = "aws bedrock-agentcore-control update-agent-runtime --cli-input-json \"file://${local_sensitive_file.runtime_update_input[0].filename}\" --region \"${data.aws_region.current.region}\" --no-cli-pager"

    environment = {
      AWS_PAGER = ""
    }
  }
}
