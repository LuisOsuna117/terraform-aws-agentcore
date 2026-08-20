mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-agentcore-role"
      id  = "mock-agentcore-role"
    }
  }

  mock_resource "aws_bedrockagentcore_agent_runtime" {
    defaults = {
      agent_runtime_id = "SecurityAgent-a1b2c3d4e5"
    }
  }
}
mock_provider "archive" {}
mock_provider "null" {}
mock_provider "time" {}

run "managed_policy_and_user_id_deny" {
  command = plan

  variables {
    name                  = "iam-security-agent"
    create_build_pipeline = false
    create_runtime        = false
    create_execution_role = true

    additional_iam_policy_arns = [
      "arn:aws:iam::aws:policy/ReadOnlyAccess",
    ]
    allow_workload_access_token_for_user_id = false
  }

  assert {
    condition     = aws_iam_role_policy_attachment.agent_execution_additional["arn:aws:iam::aws:policy/ReadOnlyAccess"].policy_arn == "arn:aws:iam::aws:policy/ReadOnlyAccess"
    error_message = "The supplied managed policy ARN must be attached to the module-created execution role."
  }

  assert {
    condition = length([
      for statement in jsondecode(aws_iam_role_policy.agent_execution[0].policy).Statement : statement
      if statement.Sid == "DenyWorkloadAccessTokenForUserId" &&
      statement.Effect == "Deny" &&
      contains(statement.Action, "bedrock-agentcore:GetWorkloadAccessTokenForUserId")
    ]) == 1
    error_message = "Disabling the UserId token path must add an explicit Deny."
  }

  assert {
    condition = length([
      for statement in jsondecode(aws_iam_role_policy.agent_execution[0].policy).Statement : statement
      if statement.Sid == "WorkloadAccessTokens" &&
      contains(statement.Action, "bedrock-agentcore:GetWorkloadAccessTokenForUserId")
    ]) == 0
    error_message = "Disabling the UserId token path must remove it from the baseline Allow statement."
  }
}
