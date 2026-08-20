# terraform-aws-agentcore v1

Greenfield, least-privilege OpenTofu/Terraform module for Amazon Bedrock AgentCore. Version 1 has no v0 inputs, aliases, moved blocks, build pipeline, CLI mutation, or compatibility resources.

Requirements:

- OpenTofu or Terraform `>= 1.11`
- AWS provider `>= 6.60, < 7`
- Caller-owned immutable container images and least-privilege IAM roles

The module exposes typed maps for Runtime/endpoints, Gateway/targets/rules, Policy, resource policies, workload Identity, Memory/strategies, Browser/Profile, Code Interpreter, Managed Harness, Registry Preview, Evaluators, online evaluations, and CloudWatch observability. Missing provider features can be isolated in `modules/preview` as caller-supplied CloudFormation; the root module never uses `local-exec`.

Registry Preview uses the current `agent-registry` API namespace. Because AWS Provider 6.60 does not yet expose that resource, `modules/agent-registry-preview` contains the only lifecycle adapter: a small SigV4 CloudFormation custom resource with manual record approval and 365-day logs. The removed `aws_bedrockagentcore_registry` resource targets the retired namespace and is intentionally unsupported.

## Dual-lane example

```hcl
module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "1.0.0"

  policy_engines = {
    itops = { name = "aegis_itops" }
  }

  gateways = {
    human = {
      name              = "aegis-human"
      role_arn          = aws_iam_role.human_gateway.arn
      authentication    = "CUSTOM_JWT"
      policy_engine_key = "itops"
      jwt = {
        discovery_url   = "${aws_cognito_user_pool.pool.endpoint}/.well-known/openid-configuration"
        allowed_clients = [aws_cognito_user_pool_client.portal.id]
      }
    }
    automation = {
      name              = "aegis-automation"
      role_arn          = aws_iam_role.automation_gateway.arn
      authentication    = "AWS_IAM"
      policy_engine_key = "itops"
    }
  }

  runtimes = {
    operator = {
      name           = "aegis_operator"
      role_arn       = aws_iam_role.operator_runtime.arn
      image_uri      = var.image_digest
      authentication = "CUSTOM_JWT"
      jwt = {
        discovery_url       = "${aws_cognito_user_pool.pool.endpoint}/.well-known/openid-configuration"
        allowed_clients     = [aws_cognito_user_pool_client.portal.id]
        allowed_gateway_key = "human"
      }
    }
    automation = {
      name           = "aegis_automation"
      role_arn       = aws_iam_role.automation_runtime.arn
      image_uri      = var.image_digest
      authentication = "AWS_IAM"
      browser_profile_id_environment = {
        AGENTCORE_BROWSER_PROFILE_ID = "readonly"
      }
    }
  }

  gateway_targets = {
    human = {
      gateway_key     = "human"
      name            = "operator-runtime"
      runtime_key     = "operator"
      credential_mode = "JWT_PASSTHROUGH"
    }
    automation = {
      gateway_key     = "automation"
      name            = "automation-runtime"
      runtime_key     = "automation"
      credential_mode = "GATEWAY_IAM_ROLE"
    }
  }
}
```

Both gateways attach policy engines in `ENFORCE` mode. The operator runtime can be restricted to the human gateway through `allowed_gateway_key`; the automation runtime has no JWT authorizer. The module deliberately does not create broad IAM roles or attach `FullAccess` policies.

## Validation

This repository is mounted into the AEGIS canonical Podman Compose toolchain. The supported gate is:

```text
podman compose --profile test run --rm test-gate
```

That gate runs formatting, validation, mocked OpenTofu tests, IAM assertions, security scanning, and secret checks in containers. No host-side OpenTofu, Terraform, Node, Python, or scanner command is supported.

Registry Preview remains shadow read-only and never grants runtime authority. Payments is intentionally absent until a real x402 flow exists. Managed Harness is intended for non-production parity and must not receive effect tools.
