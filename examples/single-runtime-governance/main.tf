provider "aws" {
  region = var.aws_region
}

module "agentcore" {
  source = "../.."

  name                  = "operations-agent"
  create_runtime        = true
  create_execution_role = true
  image_uri             = var.image_uri

  create_gateway                = true
  gateway_name                  = "operations-entry"
  gateway_authorizer_type       = "CUSTOM_JWT"
  gateway_policy_engine_mode    = "ENFORCE"
  gateway_attach_runtime_target = true

  runtime_authorizer_configuration = {
    discovery_url   = var.jwt_discovery_url
    allowed_clients = [var.jwt_client_id]
  }
  gateway_authorizer_configuration = {
    discovery_url   = var.jwt_discovery_url
    allowed_clients = [var.jwt_client_id]
  }

  create_policy_engine = true
  gateway_policy_templates = {
    runtime_access = {
      statement_template = "permit(principal, action, resource == AgentCore::Gateway::\"$${gateway_arn}\");"
    }
  }

  create_memory  = true
  create_browser = true
  runtime_environment_bindings = {
    AGENTCORE_MEMORY_ID  = "memory_id"
    AGENTCORE_BROWSER_ID = "browser_id"
  }
  runtime_memory_access_enabled  = true
  runtime_browser_access_enabled = true

  create_evaluations = true
  online_evaluations = {
    runtime = {
      use_runtime             = true
      execution_role_arn      = var.evaluation_execution_role_arn
      evaluator_ids           = ["Builtin.Helpfulness"]
      sampling_percentage     = 1
      session_timeout_minutes = 15
    }
  }

  tags = {
    Example = "single-runtime-governance"
  }
}
