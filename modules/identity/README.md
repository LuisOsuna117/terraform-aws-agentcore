# AgentCore Identity submodule

Creates opt-in AgentCore workload identities, API-key credential providers, OAuth2 credential providers, and token-vault KMS configuration.

This submodule requires Terraform or OpenTofu 1.11+ because it only accepts the AWS provider's write-only credential arguments. It never exposes credential values as outputs.

Use the focused example at [`examples/identity`](../../examples/identity).
