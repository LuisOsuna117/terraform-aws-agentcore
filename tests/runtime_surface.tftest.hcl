mock_provider "aws" {}

run "runtime_supports_agui" {
  command = plan

  module {
    source = "./modules/runtime"
  }

  variables {
    runtime_name       = "AgUiRuntime"
    execution_role_arn = "arn:aws:iam::123456789012:role/runtime-role"
    image_uri          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/runtime:v1"
    server_protocol    = "AGUI"
  }

  assert {
    condition     = one(aws_bedrockagentcore_agent_runtime.this.protocol_configuration).server_protocol == "AGUI"
    error_message = "Runtime must preserve the AG-UI server protocol."
  }
}

run "runtime_supports_code_artifact_filesystems_and_tags" {
  command = plan

  module {
    source = "./modules/runtime"
  }

  variables {
    runtime_name       = "CodeRuntime"
    execution_role_arn = "arn:aws:iam::123456789012:role/runtime-role"
    code_configuration = {
      entry_point = ["main.py"]
      runtime     = "PYTHON_3_12"
      s3 = {
        bucket     = "agentcore-source"
        prefix     = "runtime/source.zip"
        version_id = "version-1"
      }
    }
    filesystems = [{
      session_storage = { mount_path = "/mnt/session" }
      }, {
      efs_access_point = {
        access_point_arn = "arn:aws:elasticfilesystem:us-east-1:123456789012:access-point/fsap-0123456789abcdef0"
        mount_path       = "/mnt/shared"
      }
    }]
    region = "us-east-1"
    tags   = { Environment = "test" }
    timeouts = {
      create = "30m"
    }
  }

  assert {
    condition     = aws_bedrockagentcore_agent_runtime.this.agent_runtime_artifact[0].code_configuration[0].code[0].s3[0].version_id == "version-1"
    error_message = "Runtime must preserve an S3 code artifact and version."
  }

  assert {
    condition     = length(aws_bedrockagentcore_agent_runtime.this.filesystem_configuration) == 2
    error_message = "Runtime must preserve each opt-in filesystem mount."
  }

  assert {
    condition     = aws_bedrockagentcore_agent_runtime.this.tags.Environment == "test"
    error_message = "Runtime must apply caller tags."
  }
}

run "runtime_supports_advanced_jwt_authorizer" {
  command = plan

  module {
    source = "./modules/runtime"
  }

  variables {
    runtime_name       = "JwtRuntime"
    execution_role_arn = "arn:aws:iam::123456789012:role/runtime-role"
    image_uri          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/runtime:v1"
    authorizer_configuration = {
      discovery_url            = "https://example.auth.us-east-1.amazoncognito.com/.well-known/openid-configuration"
      allowed_audience         = ["runtime-api"]
      allowed_clients          = ["portal"]
      allowed_scopes           = ["openid"]
      workload_identities      = ["operator"]
      hosting_environment_arns = ["arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/operator-abcdefghij"]
      custom_claims = [{
        inbound_token_claim_name       = "cognito:groups"
        inbound_token_claim_value_type = "STRING_ARRAY"
        claim_match_operator           = "CONTAINS"
        match_value_string             = "operators"
      }]
    }
  }

  assert {
    condition     = aws_bedrockagentcore_agent_runtime.this.authorizer_configuration[0].custom_jwt_authorizer[0].allowed_scopes == toset(["openid"])
    error_message = "Runtime must preserve JWT scopes."
  }

  assert {
    condition     = one(aws_bedrockagentcore_agent_runtime.this.authorizer_configuration[0].custom_jwt_authorizer[0].custom_claim).inbound_token_claim_value_type == "STRING_ARRAY"
    error_message = "Runtime must preserve STRING_ARRAY claims."
  }
}

run "runtime_omits_unconfigured_jwt_claim_restrictions" {
  command = plan

  module {
    source = "./modules/runtime"
  }

  variables {
    runtime_name       = "ClientOnlyRuntime"
    execution_role_arn = "arn:aws:iam::123456789012:role/runtime-role"
    image_uri          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/runtime:v1"
    authorizer_configuration = {
      discovery_url   = "https://example.auth.us-east-1.amazoncognito.com/.well-known/openid-configuration"
      allowed_clients = ["portal"]
    }
  }

  assert {
    condition = (
      aws_bedrockagentcore_agent_runtime.this.authorizer_configuration[0].custom_jwt_authorizer[0].allowed_audience == null &&
      aws_bedrockagentcore_agent_runtime.this.authorizer_configuration[0].custom_jwt_authorizer[0].allowed_scopes == null
    )
    error_message = "Unconfigured JWT restrictions must be omitted instead of sent as invalid empty arrays."
  }
}

run "runtime_rejects_workload_identity_arns" {
  command = plan

  module {
    source = "./modules/runtime"
  }

  variables {
    runtime_name       = "InvalidWorkloadRuntime"
    execution_role_arn = "arn:aws:iam::123456789012:role/runtime-role"
    image_uri          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/runtime:v1"
    authorizer_configuration = {
      discovery_url = "https://example.auth.us-east-1.amazoncognito.com/.well-known/openid-configuration"
      workload_identities = [
        "arn:aws:bedrock-agentcore:us-east-1:123456789012:workload-identity-directory/default/workload-identity/operator"
      ]
    }
  }

  expect_failures = [var.authorizer_configuration]
}
