locals {
  stack_name    = substr("${replace(lower(var.name), "/[^a-z0-9-]/", "-")}-registry-preview", 0, 64)
  function_name = substr("${local.stack_name}-lifecycle", 0, 64)
  log_group     = "/aws/lambda/${local.function_name}"

  template = {
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "Current-namespace AWS Agent Registry preview resource"
    Resources = {
      LifecycleLogGroup = {
        Type = "AWS::Logs::LogGroup"
        Properties = {
          LogGroupName    = local.log_group
          RetentionInDays = var.log_retention_days
          Tags            = [for key, value in var.tags : { Key = key, Value = value }]
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
            PolicyName = "agent-registry-lifecycle"
            PolicyDocument = {
              Version = "2012-10-17"
              Statement = [
                {
                  Sid      = "CreateAndListRegistry"
                  Effect   = "Allow"
                  Action   = ["agent-registry:CreateRegistry", "agent-registry:ListRegistries"]
                  Resource = { "Fn::Sub" = "arn:$${AWS::Partition}:agent-registry:$${AWS::Region}:$${AWS::AccountId}:*" }
                },
                {
                  Sid    = "ManageExactAccountRegistries"
                  Effect = "Allow"
                  Action = [
                    "agent-registry:GetRegistry",
                    "agent-registry:DeleteRegistry",
                    "agent-registry:ListRegistryRecords",
                    "agent-registry:DeleteRegistryRecord"
                  ]
                  Resource = [
                    { "Fn::Sub" = "arn:$${AWS::Partition}:agent-registry:$${AWS::Region}:$${AWS::AccountId}:registry/*" },
                    { "Fn::Sub" = "arn:$${AWS::Partition}:agent-registry:$${AWS::Region}:$${AWS::AccountId}:registry/*/record/*" }
                  ]
                },
                {
                  Sid      = "CreateRegistryServiceLinkedRole"
                  Effect   = "Allow"
                  Action   = "iam:CreateServiceLinkedRole"
                  Resource = { "Fn::Sub" = "arn:$${AWS::Partition}:iam::$${AWS::AccountId}:role/aws-service-role/agent-registry.amazonaws.com/*" }
                  Condition = {
                    StringEquals = { "iam:AWSServiceName" = "agent-registry.amazonaws.com" }
                  }
                },
                {
                  Sid    = "WriteLifecycleLogs"
                  Effect = "Allow"
                  Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
                  Resource = {
                    "Fn::Sub" = "arn:$${AWS::Partition}:logs:$${AWS::Region}:$${AWS::AccountId}:log-group:${local.log_group}:*"
                  }
                }
              ]
            }
          }]
          Tags = [for key, value in var.tags : { Key = key, Value = value }]
        }
      }
      LifecycleFunction = {
        Type      = "AWS::Lambda::Function"
        DependsOn = ["LifecycleLogGroup"]
        Properties = {
          FunctionName = local.function_name
          Handler      = "index.lambda_handler"
          Runtime      = "python3.14"
          Timeout      = 300
          MemorySize   = 128
          Role         = { "Fn::GetAtt" = ["LifecycleRole", "Arn"] }
          Code         = { ZipFile = file("${path.module}/handler.py") }
          Tags         = [for key, value in var.tags : { Key = key, Value = value }]
        }
      }
      Registry = {
        Type = "Custom::AgentRegistry"
        Properties = {
          ServiceToken = { "Fn::GetAtt" = ["LifecycleFunction", "Arn"] }
          RegistryName = var.name
        }
      }
    }
    Outputs = {
      RegistryId  = { Value = { "Fn::GetAtt" = ["Registry", "RegistryId"] } }
      RegistryArn = { Value = { "Fn::GetAtt" = ["Registry", "RegistryArn"] } }
    }
  }
}

resource "aws_cloudformation_stack" "this" {
  name          = local.stack_name
  template_body = jsonencode(local.template)
  capabilities  = ["CAPABILITY_IAM"]
  tags          = var.tags
}
