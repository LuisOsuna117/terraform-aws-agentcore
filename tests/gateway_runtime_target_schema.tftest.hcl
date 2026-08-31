mock_provider "aws" {
  mock_resource "aws_cloudformation_stack" {
    defaults = {
      outputs = {
        TargetId   = "runtime-schema-abcdefghij"
        GatewayArn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/reviewed-gateway-abcdefghij"
      }
    }
  }
}

run "inline_schema_uses_the_isolated_cloudformation_target" {
  command = apply

  module {
    source = "./modules/gateway-runtime-target-schema"
  }

  variables {
    gateway_identifier = "reviewed-gateway-abcdefghij"
    name               = "OperatorRuntime"
    runtime_arn        = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/Operator-abcdefghij"
    qualifier          = "DEFAULT"

    schema = {
      inline_payload = {
        payload = jsonencode({
          openapi = "3.0.3"
          info    = { title = "Operator Runtime", version = "1.0.0" }
          paths   = {}
        })
      }
    }

    credential_provider_configuration = {
      gateway_iam_role = {}
    }

    metadata_configuration = {
      allowed_request_headers = ["x-correlation-id"]
    }
  }

  assert {
    condition     = jsondecode(aws_cloudformation_stack.this.template_body).Resources.RuntimeTarget.Type == "AWS::BedrockAgentCore::GatewayTarget"
    error_message = "Schema-bearing Runtime targets must use the isolated CloudFormation resource."
  }

  assert {
    condition     = startswith(aws_cloudformation_stack.this.name, "agentcore-")
    error_message = "The CloudFormation stack name must start with a letter even when the Gateway ID does not."
  }

  assert {
    condition     = strcontains(jsondecode(aws_cloudformation_stack.this.template_body).Resources.RuntimeTarget.Properties.TargetConfiguration.Http.AgentcoreRuntime.Schema.Source.InlinePayload, "Operator Runtime")
    error_message = "The Runtime target must preserve its inline API schema."
  }

  assert {
    condition     = jsondecode(aws_cloudformation_stack.this.template_body).Resources.RuntimeTarget.Properties.CredentialProviderConfigurations[0].CredentialProviderType == "GATEWAY_IAM_ROLE"
    error_message = "The isolated target must preserve the selected credential provider type."
  }

  assert {
    condition     = !contains(keys(jsondecode(aws_cloudformation_stack.this.template_body).Resources.RuntimeTarget.Properties.CredentialProviderConfigurations[0]), "CredentialProvider")
    error_message = "AgentCore Runtime targets must use the basic GATEWAY_IAM_ROLE configuration without IamCredentialProvider."
  }

  assert {
    condition     = jsondecode(aws_cloudformation_stack.this.template_body).Resources.RuntimeTarget.Properties.MetadataConfiguration.AllowedRequestHeaders == ["x-correlation-id"]
    error_message = "The isolated target must preserve metadata propagation."
  }
}

run "s3_schema_preserves_the_optional_bucket_owner" {
  command = plan

  module {
    source = "./modules/gateway-runtime-target-schema"
  }

  variables {
    gateway_identifier = "reviewed-gateway-abcdefghij"
    name               = "AutomationRuntime"
    runtime_arn        = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/Automation-abcdefghij"

    schema = {
      s3 = {
        uri                     = "s3://reviewed-schemas/autopilot.json"
        bucket_owner_account_id = "123456789012"
      }
    }
  }

  assert {
    condition     = jsondecode(aws_cloudformation_stack.this.template_body).Resources.RuntimeTarget.Properties.TargetConfiguration.Http.AgentcoreRuntime.Schema.Source.S3.BucketOwnerAccountId == "123456789012"
    error_message = "S3 schemas must preserve the expected bucket owner."
  }
}

run "ambiguous_schema_sources_are_rejected" {
  command = plan

  module {
    source = "./modules/gateway-runtime-target-schema"
  }

  variables {
    gateway_identifier = "reviewed-gateway-abcdefghij"
    name               = "AmbiguousRuntime"
    runtime_arn        = "arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/Ambiguous-abcdefghij"

    schema = {
      inline_payload = {
        payload = jsonencode({ openapi = "3.0.3", paths = {} })
      }
      s3 = {
        uri = "s3://reviewed-schemas/runtime.json"
      }
    }
  }

  expect_failures = [var.schema]
}
