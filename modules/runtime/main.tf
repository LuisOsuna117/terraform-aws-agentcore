resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = (var.image_uri != null) != (var.code_configuration != null)
      error_message = "Configure exactly one Runtime artifact: image_uri or code_configuration."
    }

    precondition {
      condition     = var.network_mode != "VPC" || (length(var.vpc_security_group_ids) > 0 && length(var.vpc_subnet_ids) > 0)
      error_message = "VPC Runtime mode requires at least one security group and subnet."
    }
  }
}

resource "aws_bedrockagentcore_agent_runtime" "this" {
  agent_runtime_name = var.runtime_name
  description        = var.description
  role_arn           = var.execution_role_arn
  region             = var.region

  agent_runtime_artifact {
    dynamic "container_configuration" {
      for_each = var.image_uri == null ? [] : [var.image_uri]
      content {
        container_uri = container_configuration.value
      }
    }

    dynamic "code_configuration" {
      for_each = var.code_configuration == null ? [] : [var.code_configuration]
      content {
        entry_point = code_configuration.value.entry_point
        runtime     = code_configuration.value.runtime

        code {
          s3 {
            bucket     = code_configuration.value.s3.bucket
            prefix     = code_configuration.value.s3.prefix
            version_id = code_configuration.value.s3.version_id
          }
        }
      }
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
    for_each = var.authorizer_configuration == null ? [] : [var.authorizer_configuration]
    content {
      custom_jwt_authorizer {
        discovery_url    = authorizer_configuration.value.discovery_url
        allowed_audience = length(authorizer_configuration.value.allowed_audience) == 0 ? null : authorizer_configuration.value.allowed_audience
        allowed_clients  = length(authorizer_configuration.value.allowed_clients) == 0 ? null : authorizer_configuration.value.allowed_clients
        allowed_scopes   = length(authorizer_configuration.value.allowed_scopes) == 0 ? null : authorizer_configuration.value.allowed_scopes

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

  dynamic "lifecycle_configuration" {
    for_each = var.idle_runtime_session_timeout != null || var.max_lifetime != null ? [1] : []
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
  tags                  = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [terraform_data.validations]
}
