mock_provider "aws" {}

run "managed_harness_has_explicit_limits" {
  command = plan

  module {
    source = "./modules/managed-harness"
  }

  variables {
    name               = "research-harness"
    execution_role_arn = "arn:aws:iam::123456789012:role/agentcore-harness"
    image_uri          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/research:1"
    system_prompt      = "Research using only the allowed tools."
    max_iterations     = 8
    max_tokens         = 4096
    timeout_seconds    = 300
    model = {
      bedrock = {
        model_id = "us.anthropic.claude-sonnet-4-6"
      }
    }
  }

  assert {
    condition     = aws_bedrockagentcore_harness.this.max_iterations == 8
    error_message = "Managed Harness limits must be explicit and caller-controlled."
  }

  assert {
    condition     = aws_bedrockagentcore_harness.this.memory[0].disabled != null
    error_message = "Memory must default to disabled until the caller opts into a Memory ARN."
  }
}

run "managed_harness_exposes_opt_in_provider_surface" {
  command = plan

  module {
    source = "./modules/managed-harness"
  }

  variables {
    name               = "portable-harness"
    execution_role_arn = "arn:aws:iam::123456789012:role/agentcore-harness"
    system_prompt      = "Use only explicitly configured tools."
    allowed_tools      = ["*"]

    model = {
      openai = {
        model_id    = "gpt-5"
        api_key_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:openai"
      }
    }

    filesystems = [{
      session_storage = {
        mount_path = "/mnt/session"
      }
    }]

    managed_memory = {
      event_expiry_duration = 14
      strategies            = ["SEMANTIC", "SUMMARIZATION"]
    }

    tools = [{
      type = "agentcore_gateway"
      name = "operations"
      config = {
        agentcore_gateway = {
          gateway_arn = "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/example"
          outbound_auth = {
            aws_iam = true
          }
        }
      }
    }]

    truncation = {
      strategy = "sliding_window"
      config = {
        sliding_window = {
          messages_count = 50
        }
      }
    }
  }

  assert {
    condition     = length(aws_bedrockagentcore_harness.this.model[0].openai_model_config) == 1
    error_message = "Managed Harness must expose the provider's OpenAI model configuration."
  }

  assert {
    condition     = length(aws_bedrockagentcore_harness.this.tool) == 1
    error_message = "Managed Harness tools must remain explicitly opt-in."
  }

  assert {
    condition     = length(aws_bedrockagentcore_harness.this.environment[0].agentcore_runtime_environment[0].filesystem_configuration) == 1
    error_message = "Managed Harness must expose runtime filesystem mounts."
  }

  assert {
    condition     = length(aws_bedrockagentcore_harness.this.memory[0].managed_memory_configuration) == 1
    error_message = "Managed Harness must expose managed Memory as an opt-in variant."
  }
}

run "jwt_authorizer_exposes_claims_and_private_endpoints" {
  command = plan

  module {
    source = "./modules/managed-harness"
  }

  variables {
    name               = "private-authorizer"
    execution_role_arn = "arn:aws:iam::123456789012:role/agentcore-harness"
    system_prompt      = "Authenticate every caller."
    model = {
      gemini = {
        model_id    = "gemini-2.5-pro"
        api_key_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:gemini"
      }
    }
    jwt_authorizer = {
      discovery_url = "https://auth.example.com/.well-known/openid-configuration"
      custom_claims = [{
        inbound_token_claim_name       = "groups"
        inbound_token_claim_value_type = "STRING_ARRAY"
        claim_match_operator           = "CONTAINS_ANY"
        match_value_string_list        = ["operators"]
      }]
      private_endpoint = {
        self_managed_lattice_resource = {
          resource_configuration_identifier = "rcfg-abcdefghij"
        }
      }
      private_endpoint_overrides = [{
        domain = "auth.example.com"
        private_endpoint = {
          self_managed_lattice_resource = {
            resource_configuration_identifier = "rcfg-klmnopqrst"
          }
        }
      }]
    }
  }

  assert {
    condition     = length(aws_bedrockagentcore_harness.this.authorizer_configuration[0].custom_jwt_authorizer[0].custom_claim) == 1
    error_message = "JWT custom claims must be represented without application-specific policy."
  }

  assert {
    condition     = length(aws_bedrockagentcore_harness.this.authorizer_configuration[0].custom_jwt_authorizer[0].private_endpoint) == 1
    error_message = "JWT authorizer private endpoints must remain opt-in."
  }
}
