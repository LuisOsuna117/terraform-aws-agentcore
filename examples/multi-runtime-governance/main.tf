# One root module instance composes two independently authorized execution
# lanes. Every capability remains opt-in; remove a flag or map entry when the
# workload does not need that service.
module "agentcore" {
  source = "../.."
  # Uncomment once this interface is published to the registry:
  # source  = "LuisOsuna117/agentcore/aws"
  # version = "~> 1.3"

  name = var.name

  create_runtime        = true
  create_execution_role = true
  image_uri             = var.image_uri

  runtime_authorizer_configuration = {
    discovery_url   = var.jwt_discovery_url
    allowed_clients = var.jwt_allowed_clients
  }

  create_gateway          = true
  gateway_name            = "${var.name}-interactive"
  gateway_authorizer_type = "CUSTOM_JWT"
  gateway_authorizer_configuration = {
    discovery_url   = var.jwt_discovery_url
    allowed_clients = var.jwt_allowed_clients
  }
  gateway_attach_runtime_target           = true
  runtime_trust_gateway_workload_identity = true
  gateway_runtime_target = {
    credential_provider_configuration = {
      jwt_passthrough = {}
    }
  }

  create_memory  = true
  create_browser = true

  runtime_memory_access_enabled  = true
  runtime_browser_access_enabled = true
  runtime_environment_bindings = {
    AGENTCORE_MEMORY_ID  = { source = "memory_id" }
    AGENTCORE_BROWSER_ID = { source = "browser_id" }
  }

  create_policy_engine       = true
  gateway_policy_engine_mode = "LOG_ONLY"

  additional_iam_statements = [{
    Sid      = "InvokeConfiguredModels"
    Effect   = "Allow"
    Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    Resource = var.model_arns
  }]

  additional_runtimes = {
    automation = {
      name                  = "${var.name}-automation"
      create_execution_role = true
      image_uri             = var.image_uri
      additional_iam_statements = [{
        Sid      = "InvokeConfiguredModels"
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
        Resource = var.model_arns
      }]
      resource_policy_configuration = {
        gateway_keys = ["automation"]
      }
    }
  }

  additional_gateways = {
    automation = {
      name                      = "${var.name}-automation"
      authorizer_type           = "AWS_IAM"
      runtime_key               = "automation"
      policy_engine_mode        = "LOG_ONLY"
      resource_policy_role_arns = var.automation_caller_role_arns
    }
  }

  tags = var.tags
}
