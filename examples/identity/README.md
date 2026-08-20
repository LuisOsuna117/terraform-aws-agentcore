# AgentCore Identity

This example creates AgentCore workload identity and outbound API-key/OAuth2 credential providers without storing credential values in Terraform state.

```hcl
module "identity" {
  source = "../../modules/identity"

  name = "my-agent"

  api_key_credential_providers = {
    external_api = { secret_version = 1 }
  }
  api_key_values = {
    external_api = var.api_key
  }
}
```

Supply secrets through sensitive variables or an ephemeral CI mechanism. Increment the matching version when rotating a credential.
