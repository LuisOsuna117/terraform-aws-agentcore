data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  effective_region = coalesce(var.region, data.aws_region.current.region)
  gateway_arn      = "arn:${data.aws_partition.current.partition}:bedrock-agentcore:${local.effective_region}:${data.aws_caller_identity.current.account_id}:gateway/${var.gateway_identifier}"
  stack_name       = substr("${var.gateway_identifier}-${var.name}-connector-target", 0, 128)

  connector_configurations = [
    for configuration in var.configurations : {
      Name            = configuration.name
      ParameterValues = configuration.parameter_values
    }
  ]

  target_properties = merge(
    {
      GatewayIdentifier = var.gateway_identifier
      Name              = var.name
      TargetConfiguration = {
        Mcp = {
          Connector = {
            Source = {
              ConnectorId = var.connector_id
              Version     = var.connector_version
            }
            Configurations = local.connector_configurations
          }
        }
      }
      CredentialProviderConfigurations = [{
        CredentialProviderType = "GATEWAY_IAM_ROLE"
      }]
    },
    var.description == null ? {} : { Description = var.description },
  )

  template = {
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "Native AgentCore Gateway connector target."
    Resources = {
      ConnectorTarget = {
        Type       = "AWS::BedrockAgentCore::GatewayTarget"
        Properties = local.target_properties
      }
    }
    Outputs = {
      TargetId = {
        Value = { "Fn::GetAtt" = ["ConnectorTarget", "TargetId"] }
      }
      GatewayArn = {
        Value = { "Fn::GetAtt" = ["ConnectorTarget", "GatewayArn"] }
      }
    }
  }
}

resource "aws_cloudformation_stack" "this" {
  name          = local.stack_name
  region        = var.region
  template_body = jsonencode(local.template)
  tags          = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
