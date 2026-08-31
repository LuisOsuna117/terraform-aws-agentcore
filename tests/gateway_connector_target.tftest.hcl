mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }
}

run "connector_version_and_admin_policy_are_explicit" {
  command = plan

  module {
    source = "./modules/gateway-connector-target"
  }

  variables {
    gateway_identifier = "reviewed-gateway-abcdefghij"
    name               = "web-search"
    connector_id       = "web-search"
    connector_version  = "1.2.0"
    configurations = [{
      name = "WebSearch"
      parameter_values = {
        domainFilter = {
          include = ["docs.aws.amazon.com"]
          exclude = ["example.invalid"]
        }
      }
    }]
  }

  assert {
    condition     = jsondecode(aws_cloudformation_stack.this.template_body).Resources.ConnectorTarget.Properties.TargetConfiguration.Mcp.Connector.Source.Version == "1.2.0"
    error_message = "The connector target must pin the requested version."
  }

  assert {
    condition     = jsondecode(aws_cloudformation_stack.this.template_body).Resources.ConnectorTarget.Properties.TargetConfiguration.Mcp.Connector.Configurations[0].ParameterValues.domainFilter.include == ["docs.aws.amazon.com"]
    error_message = "Target-level connector configuration must be passed without weakening it."
  }
}

run "connector_uses_native_cloudformation_without_a_lifecycle_provider" {
  command = plan

  module {
    source = "./modules/gateway-connector-target"
  }

  variables {
    gateway_identifier = "reviewed-gateway-abcdefghij"
    name               = "web-search"
    connector_id       = "web-search"
    connector_version  = "1.2.0"
    configurations     = [{ name = "WebSearch" }]
  }

  assert {
    condition     = jsondecode(aws_cloudformation_stack.this.template_body).Resources.ConnectorTarget.Type == "AWS::BedrockAgentCore::GatewayTarget"
    error_message = "Connector targets must use the native CloudFormation resource."
  }

  assert {
    condition     = !strcontains(aws_cloudformation_stack.this.template_body, "AWS::Lambda::Function")
    error_message = "Native connector targets must not carry a custom lifecycle Lambda."
  }

  assert {
    condition     = jsondecode(aws_cloudformation_stack.this.template_body).Resources.ConnectorTarget.Properties.GatewayIdentifier == "reviewed-gateway-abcdefghij"
    error_message = "The native connector target must remain scoped to one Gateway."
  }
}
