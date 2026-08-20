mock_provider "aws" {}

run "browser_defaults_to_public_and_profiles_are_optional" {
  command = plan

  module {
    source = "./modules/browser"
  }

  variables {
    name = "research-browser"
    profiles = {
      operator = {}
    }
  }

  assert {
    condition     = aws_bedrockagentcore_browser.this[0].network_configuration[0].network_mode == "PUBLIC"
    error_message = "Browser must default to PUBLIC unless the caller opts into VPC networking."
  }

  assert {
    condition     = length(output.profile_ids) == 1
    error_message = "Each requested Browser Profile must be created."
  }
}

run "profile_only_mode" {
  command = plan

  module {
    source = "./modules/browser"
  }

  variables {
    name           = "profile-only"
    create_browser = false
    profiles = {
      shared = {}
    }
  }

  assert {
    condition     = output.browser_id == null
    error_message = "The Browser resource must remain opt-in when profile-only mode is selected."
  }
}
