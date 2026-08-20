provider "aws" {
  region = var.region
}

module "agentcore" {
  source = "../.."

  name = var.name

  policy_engines = {
    access = {}
  }

  gateways = {
    human = {
      role_arn          = var.human_gateway_role_arn
      authentication    = "CUSTOM_JWT"
      policy_engine_key = "access"
      jwt = {
        discovery_url   = var.jwt_discovery_url
        allowed_clients = [var.jwt_client_id]
      }
    }
    automation = {
      role_arn          = var.automation_gateway_role_arn
      authentication    = "AWS_IAM"
      policy_engine_key = "access"
    }
  }

  runtimes = {
    operator = {
      role_arn       = var.operator_runtime_role_arn
      image_uri      = var.image_uri
      authentication = "CUSTOM_JWT"
      jwt = {
        discovery_url       = var.jwt_discovery_url
        allowed_clients     = [var.jwt_client_id]
        allowed_gateway_key = "human"
      }
    }
    automation = {
      role_arn       = var.automation_runtime_role_arn
      image_uri      = var.image_uri
      authentication = "AWS_IAM"
    }
  }

  gateway_targets = {
    human = {
      gateway_key     = "human"
      target_type     = "HTTP_RUNTIME"
      runtime_key     = "operator"
      credential_mode = "JWT_PASSTHROUGH"
    }
    automation = {
      gateway_key     = "automation"
      target_type     = "HTTP_RUNTIME"
      runtime_key     = "automation"
      credential_mode = "GATEWAY_IAM_ROLE"
    }
  }

  tags = {
    Environment = "example"
    Terraform   = "true"
  }
}
