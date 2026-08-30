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
    condition     = jsondecode(aws_cloudformation_stack.this.template_body).Resources.ConnectorTarget.Properties.ConnectorVersion == "1.2.0"
    error_message = "The connector target must pin the requested version."
  }

  assert {
    condition     = jsondecode(aws_cloudformation_stack.this.template_body).Resources.ConnectorTarget.Properties.Configurations[0].parameterValues.domainFilter.include == ["docs.aws.amazon.com"]
    error_message = "Target-level connector configuration must be passed without weakening it."
  }
}

run "lifecycle_provider_is_scoped_to_one_gateway" {
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
    condition     = jsondecode(aws_cloudformation_stack.this.template_body).Resources.LifecycleRole.Properties.Policies[0].PolicyDocument.Statement[1].Resource == "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/reviewed-gateway-abcdefghij"
    error_message = "Connector target lifecycle permissions must be scoped to the configured Gateway."
  }

  assert {
    condition     = !strcontains(aws_cloudformation_stack.this.template_body, "FullAccess")
    error_message = "The connector target lifecycle provider must not use FullAccess policies."
  }

  assert {
    condition     = contains(jsondecode(aws_cloudformation_stack.this.template_body).Resources.LifecycleRole.Properties.Policies[0].PolicyDocument.Statement[1].Action, "bedrock-agentcore:SynchronizeGatewayTargets")
    error_message = "Connector target lifecycle permissions must include the synchronization dependency documented by AgentCore."
  }
}
