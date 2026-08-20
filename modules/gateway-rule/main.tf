locals {
  configured_actions = compact([
    var.static_target_name == null ? "" : "static_target",
    length(var.weighted_targets) == 0 ? "" : "weighted_targets",
    var.static_configuration_bundle == null ? "" : "static_configuration_bundle",
    length(var.weighted_configuration_bundles) == 0 ? "" : "weighted_configuration_bundles",
  ])
}

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = length(var.paths) > 0
      error_message = "paths must contain at least one path."
    }

    precondition {
      condition     = length(local.configured_actions) == 1
      error_message = "Configure exactly one of static_target_name, weighted_targets, static_configuration_bundle, or weighted_configuration_bundles."
    }
  }
}

resource "aws_bedrockagentcore_gateway_rule" "this" {
  gateway_identifier = var.gateway_identifier
  priority           = var.priority
  description        = var.description

  condition {
    match_paths {
      any_of = var.paths
    }

    dynamic "match_principals" {
      for_each = length(var.iam_principals) == 0 ? [] : [var.iam_principals]
      content {
        any_of {
          dynamic "iam_principal" {
            for_each = match_principals.value
            content {
              arn = iam_principal.value
            }
          }
        }
      }
    }
  }

  action {
    dynamic "route_to_target" {
      for_each = var.static_target_name != null || length(var.weighted_targets) > 0 ? [1] : []
      content {
        dynamic "static_route" {
          for_each = var.static_target_name == null ? [] : [var.static_target_name]
          content {
            target_name = static_route.value
          }
        }

        dynamic "weighted_route" {
          for_each = length(var.weighted_targets) == 0 ? [] : [var.weighted_targets]
          content {
            dynamic "traffic_split" {
              for_each = weighted_route.value
              content {
                name        = traffic_split.value.name
                target_name = traffic_split.value.target_name
                weight      = traffic_split.value.weight
                description = traffic_split.value.description
                metadata    = traffic_split.value.metadata
              }
            }
          }
        }
      }
    }

    dynamic "configuration_bundle" {
      for_each = var.static_configuration_bundle != null || length(var.weighted_configuration_bundles) > 0 ? [1] : []
      content {
        dynamic "static_override" {
          for_each = var.static_configuration_bundle == null ? [] : [var.static_configuration_bundle]
          content {
            bundle_arn     = static_override.value.bundle_arn
            bundle_version = static_override.value.bundle_version
          }
        }

        dynamic "weighted_override" {
          for_each = length(var.weighted_configuration_bundles) == 0 ? [] : [var.weighted_configuration_bundles]
          content {
            dynamic "traffic_split" {
              for_each = weighted_override.value
              content {
                name        = traffic_split.value.name
                weight      = traffic_split.value.weight
                description = traffic_split.value.description
                metadata    = traffic_split.value.metadata
                configuration_bundle {
                  bundle_arn     = traffic_split.value.bundle_arn
                  bundle_version = traffic_split.value.bundle_version
                }
              }
            }
          }
        }
      }
    }
  }

  depends_on = [terraform_data.validations]
}
