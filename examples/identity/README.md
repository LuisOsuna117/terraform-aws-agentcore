# AgentCore Identity

Creates an AgentCore workload identity and an OAuth2 credential provider using
the AWS provider write-only credential fields. Secrets are never exposed by the
module outputs.

Supply sensitive values through your normal secret-injection mechanism. Do not
commit them to `.tfvars` files.

When copying this example, replace `source = "../.."` with the registry source
and pin the module version.
