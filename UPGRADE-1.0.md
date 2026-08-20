# Upgrade to v1.0

Version 1.0 replaces the Gateway Target compatibility layer with the native `aws_bedrockagentcore_gateway_target` resource from AWS Provider 6.61. This is intentionally a breaking change: v1 does not retain aliases or CloudFormation-managed target resources.

## Explicit resource creation

The root module is opt-in in v1. A call containing only `name` creates no
resources. Enable the composition you need explicitly:

```hcl
create_build_pipeline  = true
trigger_build_on_apply = true
create_runtime         = true
create_execution_role  = true
```

The build trigger, broad Bedrock managed policy, wildcard model invocation,
UserId workload-token path, ECR repository policy, and ECR lifecycle policy
are disabled by default. Set `ecr_lifecycle_keep_count` or
`ecr_pull_principals` only when you want those resources.

For an externally built Runtime, provide a tagged or digest-pinned Amazon ECR
URI and enable Runtime explicitly. For CodeBuild without an apply-time trigger,
create the build infrastructure first, push the image, and enable Runtime in a
second apply. See the focused examples for both workflows.

## Gateway Target configuration

Replace `target_type`, flat endpoint/Runtime fields, and `gateway_mcp_targets` with the native `target_configuration` shape:

```hcl
gateway_targets = {
  runtime = {
    target_configuration = {
      http = {
        agentcore_runtime = {
          arn       = var.runtime_arn
          qualifier = "DEFAULT"
        }
      }
    }
    credential_provider_configuration = {
      gateway_iam_role = {
        service = "bedrock-agentcore"
      }
    }
  }
}
```

The same map supports `mcp.api_gateway`, `mcp.lambda`, `mcp.mcp_server`, `mcp.open_api_schema`, and `mcp.smithy_model`. Use `gateway_target_invocation_urls` instead of `gateway_agent_target_invocation_urls`; the MCP-only endpoint output was removed.

## Existing Gateway Targets

CloudFormation stacks and native Gateway Target resources have different Terraform resource types, so Terraform cannot move their state directly. Do not attempt a one-step in-place upgrade or edit state by hand.

The recommended migration is blue/green:

1. Keep the existing v0.x module instance and Gateway running.
2. Add a v1 module instance with a different `name` and the new target configuration.
3. Validate authentication, target routing, policies, and clients against the v1 Gateway URL.
4. Move callers to the v1 Gateway.
5. Remove the v0.x module instance after the rollback window expires.

If temporary downtime is acceptable, first apply v0.x with all Gateway Target maps empty, then upgrade the module to v1 and apply the new `gateway_targets` configuration. Review both plans before applying.

## Requirements

- AWS Provider `>= 6.61, < 7.0`
- OpenTofu or Terraform `>= 1.11`
- GitHub-hosted or self-hosted Actions runners compatible with Node.js 24 when using the included workflows
