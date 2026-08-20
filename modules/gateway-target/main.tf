resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition = (
        (var.target_type == "HTTP_RUNTIME") == (var.runtime_arn != null) &&
        (var.target_type == "MCP_SERVER") == (var.mcp_endpoint != null)
      )
      error_message = "HTTP_RUNTIME requires only runtime_arn; MCP_SERVER requires only mcp_endpoint."
    }

    precondition {
      condition     = !contains(["API_KEY", "OAUTH"], var.credential_mode) || var.credential_provider_arn != null
      error_message = "API_KEY and OAUTH credential modes require credential_provider_arn."
    }

    precondition {
      condition = !contains(["GATEWAY_IAM_ROLE", "CALLER_IAM_CREDENTIALS"], var.credential_mode) || (
        var.signing_service != null && var.signing_region != null
      )
      error_message = "IAM credential modes require signing_service and signing_region."
    }
  }
}

resource "aws_bedrockagentcore_gateway_target" "this" {
  gateway_identifier = var.gateway_identifier
  name               = var.name
  description        = var.description

  credential_provider_configuration {
    dynamic "jwt_passthrough" {
      for_each = var.credential_mode == "JWT_PASSTHROUGH" ? [1] : []
      content {}
    }

    dynamic "gateway_iam_role" {
      for_each = var.credential_mode == "GATEWAY_IAM_ROLE" ? [1] : []
      content {
        service = var.signing_service
        region  = var.signing_region
      }
    }

    dynamic "caller_iam_credentials" {
      for_each = var.credential_mode == "CALLER_IAM_CREDENTIALS" ? [1] : []
      content {
        service = var.signing_service
        region  = var.signing_region
      }
    }

    dynamic "api_key" {
      for_each = var.credential_mode == "API_KEY" ? [1] : []
      content {
        provider_arn              = var.credential_provider_arn
        credential_location       = var.api_key_location
        credential_parameter_name = var.api_key_parameter_name
        credential_prefix         = var.api_key_prefix
      }
    }

    dynamic "oauth" {
      for_each = var.credential_mode == "OAUTH" ? [1] : []
      content {
        provider_arn       = var.credential_provider_arn
        grant_type         = var.oauth_grant_type
        scopes             = var.oauth_scopes
        default_return_url = var.oauth_default_return_url
        custom_parameters  = var.oauth_custom_parameters
      }
    }
  }

  target_configuration {
    dynamic "http" {
      for_each = var.target_type == "HTTP_RUNTIME" ? [1] : []
      content {
        agentcore_runtime {
          arn       = var.runtime_arn
          qualifier = var.runtime_qualifier
        }
      }
    }

    dynamic "mcp" {
      for_each = var.target_type == "MCP_SERVER" ? [1] : []
      content {
        mcp_server {
          endpoint     = var.mcp_endpoint
          listing_mode = var.mcp_listing_mode
        }
      }
    }
  }

  dynamic "metadata_configuration" {
    for_each = length(var.allowed_query_parameters) + length(var.allowed_request_headers) + length(var.allowed_response_headers) == 0 ? [] : [1]
    content {
      allowed_query_parameters = var.allowed_query_parameters
      allowed_request_headers  = var.allowed_request_headers
      allowed_response_headers = var.allowed_response_headers
    }
  }

  depends_on = [terraform_data.validations]
}
