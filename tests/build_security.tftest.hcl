mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
      id  = "mock-role"
    }
  }
}
mock_provider "archive" {}
mock_provider "null" {}
mock_provider "time" {}

run "root_features_are_opt_in" {
  command = plan

  variables {
    name = "opt-in-agent"
  }

  assert {
    condition = alltrue([
      length(module.build) == 0,
      length(module.runtime) == 0,
      length(aws_iam_role.agent_execution) == 0,
      length(aws_iam_role_policy.agent_execution) == 0,
      length(aws_iam_role_policy_attachment.agent_execution_managed) == 0,
    ])
    error_message = "Supplying only name must not create build, Runtime, or execution-role resources."
  }
}

run "build_repository_controls_are_opt_in" {
  command = plan

  module {
    source = "./modules/build"
  }

  variables {
    name                = "build-security"
    ecr_repository_name = "build-security"
    agent_source_dir    = "./examples/basic/agent-code"
  }

  assert {
    condition     = length(aws_ecr_repository_policy.this) == 0
    error_message = "An empty pull-principal list must not create an ECR repository policy."
  }

  assert {
    condition     = length(aws_ecr_lifecycle_policy.this) == 0
    error_message = "The build module must not expire images unless the caller opts in."
  }
}

run "invalid_image_tag_is_rejected" {
  command = plan

  module {
    source = "./modules/build"
  }

  variables {
    name                = "build-security"
    ecr_repository_name = "build-security"
    agent_source_dir    = "./examples/basic/agent-code"
    image_tag           = "latest; touch /tmp/injected"
  }

  expect_failures = [var.image_tag]
}
