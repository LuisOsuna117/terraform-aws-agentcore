# Upgrade to v1.0

Version 1.0 replaces the Gateway Target compatibility layer with the native `aws_bedrockagentcore_gateway_target` resource from AWS Provider 6.61. This is intentionally a breaking change: v1 does not retain aliases or CloudFormation-managed target resources.

## Preflight

The AWS Provider constraint applies to the caller's entire root configuration,
not only to this module. Before changing the module version:

1. Use `terraform providers` to find every transitive AWS Provider constraint.
2. Back up state with the mechanism appropriate for your backend. As an
   additional portable snapshot, run `terraform state pull > pre-v1.tfstate`.
3. Commit the current `.terraform.lock.hcl`, then run `terraform init -upgrade`
   and review the lockfile diff.
4. Generate and inspect a saved plan:

   ```bash
   terraform plan -out=v1-upgrade.tfplan
   terraform show v1-upgrade.tfplan
   ```

5. Exercise the upgrade first in a non-production workspace and AWS account.
   Stop if another module cannot use AWS Provider `>= 6.61, < 7.0`.

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

## Public contract map

### Root inputs

| v0.x input | v1.0 replacement | Action |
|---|---|---|
| `authorizer_discovery_url` | `runtime_authorizer_configuration.discovery_url` | Move into the Runtime authorizer object. |
| `authorizer_allowed_audience` | `runtime_authorizer_configuration.allowed_audience` | Move into the Runtime authorizer object. |
| `authorizer_allowed_clients` | `runtime_authorizer_configuration.allowed_clients` | Move into the Runtime authorizer object. |
| `runtime_metadata_configuration` | None | Removed without replacement. v1 does not run an imperative Runtime metadata bridge. Verify any required account-level Runtime control separately. |
| `gateway_mcp_targets` | `gateway_targets` | Use the native `target_configuration.mcp` branch. |
| `gateway_targets[*].target_type` | None | Select `target_configuration.http` or `target_configuration.mcp` instead. |
| Flat target `endpoint`, `agent_runtime_arn`, `qualifier`, and `schema` fields | `target_configuration` | Place each value in the corresponding native target branch. |
| Flat target header/query allowlists | `metadata_configuration` | Move propagation settings into the target metadata object. |

### Root outputs

| v0.x output | v1.0 replacement | Action |
|---|---|---|
| `container_image_uri` | `effective_image_uri` | Rename the reference. |
| `gateway_agent_target_invocation_urls` | `gateway_target_invocation_urls` | Rename the reference; the map now represents HTTP Runtime targets. |
| `gateway_target_endpoints` | None | Removed without replacement. Keep the MCP endpoint in caller configuration and use `gateway_target_ids` for managed target identities. |
| `agent_runtime_metadata_configuration` | None | Removed with the Runtime metadata bridge. |

### Direct submodule consumers

| v0.x submodule contract | v1.0 replacement |
|---|---|
| `modules/runtime` flat authorizer inputs | `authorizer_configuration` object |
| `modules/runtime.metadata_configuration` input/output | Removed without replacement |
| `modules/gateway.mcp_targets` | `targets` with native target objects |
| `modules/gateway.agent_runtime_target_keys` | Not needed; HTTP Runtime targets are inferred from `target_configuration` |
| `modules/gateway.gateway_target_endpoints` | Removed without replacement |
| `modules/gateway.gateway_agent_target_invocation_urls` | `gateway_target_invocation_urls` |

### Changed defaults

These v0.x conveniences are disabled in v1.0 and must be re-enabled
individually when intentional:

| Behavior | v1.0 opt-in |
|---|---|
| Build pipeline | `create_build_pipeline = true` |
| Runtime | `create_runtime = true` |
| Module-created execution role | `create_execution_role = true` |
| Build triggered during apply | `trigger_build_on_apply = true` |
| `BedrockAgentCoreFullAccess` attachment | `attach_bedrock_fullaccess_policy = true` |
| Wildcard model invocation | `allow_bedrock_invoke_all = true` |
| UserId workload-token path | `allow_workload_access_token_for_user_id = true` |
| ECR image expiration | Set `ecr_lifecycle_keep_count` |
| ECR repository pull policy | Set `ecr_pull_principals` |

## Gateway Target configuration

Replace `target_type`, flat endpoint/Runtime fields, and `gateway_mcp_targets`
with the native `target_configuration` shape. For example, an external MCP
server changes from:

```hcl
gateway_mcp_targets = {
  inventory = {
    endpoint                 = "https://inventory.example.com/mcp"
    allowed_request_headers  = ["x-request-id"]
    allowed_response_headers = ["x-request-id"]
  }
}
```

to:

```hcl
gateway_targets = {
  inventory = {
    target_configuration = {
      mcp = {
        mcp_server = {
          endpoint = "https://inventory.example.com/mcp"
        }
      }
    }
    metadata_configuration = {
      allowed_request_headers  = ["x-request-id"]
      allowed_response_headers = ["x-request-id"]
    }
  }
}
```

An HTTP Runtime target uses the same map with the HTTP branch and an explicit
credential provider:

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

The same map supports `mcp.api_gateway`, `mcp.lambda`, `mcp.mcp_server`,
`mcp.open_api_schema`, and `mcp.smithy_model`. Use
`gateway_target_invocation_urls` instead of
`gateway_agent_target_invocation_urls`; the MCP-only endpoint output was
removed.

## Existing Gateway Targets

CloudFormation stacks and native Gateway Target resources have different Terraform resource types, so Terraform cannot move their state directly. Do not attempt a one-step in-place upgrade or edit state by hand.

Blue/green requires two different Terraform module addresses. Changing only
`name` inside the existing `module "agentcore"` block does not preserve the
old deployment for rollback:

```hcl
module "agentcore_v0" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 0.8"

  # Existing v0.x configuration remains unchanged during migration.
}

module "agentcore_v1" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 1.0"

  name = "agent-v1"

  # Explicit v1 resources and native Gateway Target configuration.
}
```

The recommended sequence is:

1. Keep the existing v0.x module instance and Gateway running.
2. Add a v1 module instance at a different module address, with a different `name` and the new target configuration.
3. Validate authentication, target routing, policies, and clients against the v1 Gateway URL.
4. Move callers to the v1 Gateway.
5. Remove the v0.x module instance after the rollback window expires.

If temporary downtime is acceptable, first apply v0.x with all Gateway Target maps empty, then upgrade the module to v1 and apply the new `gateway_targets` configuration. Review both plans before applying.

## Expected plan changes

The following removals can be expected when their v1 opt-ins are absent:

- CloudFormation stacks used by the v0.x Gateway Target compatibility layer;
- the ECR lifecycle policy and ECR repository policy;
- the broad managed-policy attachment and wildcard statements previously
  enabled by default;
- removed outputs and aliases, which disappear from state output without
  destroying their underlying resources.

Native `aws_bedrockagentcore_gateway_target` resources are new addresses and
cannot inherit CloudFormation-managed target state. Any planned destruction or
replacement of a Runtime, Gateway, Memory, Identity resource, source bucket, or
ECR repository outside the list above is a stop condition. Do not apply until
the cause is understood and the plan matches the intended migration.

## Pre-release AWS smoke checklist

Run this checklist in a disposable non-production AWS account before tagging
v1.0.0. Save the plan, apply output, invocation response, and destroy output for
each scenario. Do not use production state or credentials.

- [ ] Apply a Runtime and HTTP Gateway Target with a module-created Gateway IAM
  role. Invoke the Runtime through the Gateway and confirm the response and
  Runtime logs.
- [ ] Apply an MCP Gateway Target and invoke one allowed tool through the
  Gateway. Confirm that target discovery, credential handling, and the returned
  payload match the configured target.
- [ ] Apply a Gateway with `create_role = false` and a caller-owned IAM role.
  Confirm that the module neither changes nor attaches policies to that role.
- [ ] Apply the `codebuild-no-trigger` example with `create_runtime = false`,
  start the build explicitly, confirm that the image is present in ECR, then
  enable and invoke the Runtime.
- [ ] Deploy v0.8 and v1.0 at separate module addresses, move a test caller to
  the v1 Gateway, then move it back to v0.8 without changing either state.
- [ ] Destroy and recreate every scenario. Confirm that no unexpected
  CloudFormation compatibility stack, orphaned Gateway Target, IAM attachment,
  source bucket, or ECR policy remains.

Stop the release if an invocation fails, a plan replaces a shared Runtime,
Gateway, Memory, Identity resource, source bucket, or ECR repository, a
caller-owned IAM role changes, or cleanup leaves resources that require manual
state edits.

## Requirements

- AWS Provider `>= 6.61, < 7.0`
- OpenTofu or Terraform `>= 1.11`
- GitHub-hosted or self-hosted Actions runners compatible with Node.js 24 when using the included workflows
