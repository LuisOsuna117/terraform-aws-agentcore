data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  effective_region = coalesce(var.region, data.aws_region.current.region)
  gateway_arn      = "arn:${data.aws_partition.current.partition}:bedrock-agentcore:${local.effective_region}:${data.aws_caller_identity.current.account_id}:gateway/${var.gateway_identifier}"
  resource_key     = "${var.gateway_identifier}-${var.name}"
  stack_name       = substr("${local.resource_key}-connector-target", 0, 128)
  function_name    = "${substr(local.resource_key, 0, 50)}-${substr(sha256(local.resource_key), 0, 12)}"
  log_group_name   = "/aws/lambda/${local.function_name}"

  connector_configurations = [
    for configuration in var.configurations : {
      name            = configuration.name
      parameterValues = configuration.parameter_values
    }
  ]

  connector_properties = merge(
    {
      ServiceToken      = { "Fn::GetAtt" = ["LifecycleHandler", "Arn"] }
      GatewayIdentifier = var.gateway_identifier
      Name              = var.name
      ConnectorId       = var.connector_id
      ConnectorVersion  = var.connector_version
      Configurations    = local.connector_configurations
      Region            = local.effective_region
      Endpoint          = "https://bedrock-agentcore-control.${local.effective_region}.${data.aws_partition.current.dns_suffix}"
    },
    var.description == null ? {} : { Description = var.description },
  )

  template = {
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "Lifecycle provider for an AgentCore Gateway connector target."
    Resources = {
      LifecycleLogGroup = {
        Type = "AWS::Logs::LogGroup"
        Properties = {
          LogGroupName    = local.log_group_name
          RetentionInDays = var.log_retention_in_days
          Tags = [
            for key, value in var.tags : { Key = key, Value = value }
          ]
        }
      }
      LifecycleRole = {
        Type = "AWS::IAM::Role"
        Properties = {
          AssumeRolePolicyDocument = {
            Version = "2012-10-17"
            Statement = [{
              Effect    = "Allow"
              Principal = { Service = "lambda.amazonaws.com" }
              Action    = "sts:AssumeRole"
            }]
          }
          Policies = [{
            PolicyName = "AgentCoreConnectorTargetLifecycle"
            PolicyDocument = {
              Version = "2012-10-17"
              Statement = [
                {
                  Sid      = "WriteLifecycleLogs"
                  Effect   = "Allow"
                  Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
                  Resource = "arn:${data.aws_partition.current.partition}:logs:${local.effective_region}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}:*"
                },
                {
                  Sid    = "ManageOneGatewayConnectorTarget"
                  Effect = "Allow"
                  Action = [
                    "bedrock-agentcore:CreateGatewayTarget",
                    "bedrock-agentcore:GetGatewayTarget",
                    "bedrock-agentcore:UpdateGatewayTarget",
                    "bedrock-agentcore:DeleteGatewayTarget",
                    "bedrock-agentcore:SynchronizeGatewayTargets",
                  ]
                  Resource = local.gateway_arn
                },
              ]
            }
          }]
          Tags = [
            for key, value in var.tags : { Key = key, Value = value }
          ]
        }
      }
      LifecycleHandler = {
        Type      = "AWS::Lambda::Function"
        DependsOn = ["LifecycleLogGroup", "LifecycleRole"]
        Properties = {
          Code         = { ZipFile = file("${path.module}/handler.py") }
          Handler      = "index.handler"
          MemorySize   = 128
          Role         = { "Fn::GetAtt" = ["LifecycleRole", "Arn"] }
          Runtime      = "python3.13"
          Timeout      = 900
          FunctionName = local.function_name
          Tags = [
            for key, value in var.tags : { Key = key, Value = value }
          ]
        }
      }
      ConnectorTarget = {
        Type       = "Custom::AgentCoreGatewayConnectorTarget"
        DependsOn  = ["LifecycleHandler"]
        Properties = local.connector_properties
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
  capabilities  = ["CAPABILITY_IAM"]
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
