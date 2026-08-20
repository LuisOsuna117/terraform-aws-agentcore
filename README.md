# AWS AgentCore Terraform module

Terraform module which creates Amazon Bedrock AgentCore resources.

> **Community module:** maintained independently by
> [LuisOsuna117](https://github.com/LuisOsuna117). It is not affiliated with or
> endorsed by AWS, HashiCorp, or the OpenTofu project.

The root module provides one composable interface for Runtime, Gateway,
Policy, Identity, Memory, Browser, Code Interpreter, Harness, Evaluations,
Registry Preview, and observability resources. It supports Terraform and
OpenTofu.

## Features

- Runtime and immutable Runtime endpoints with `AWS_IAM` or `CUSTOM_JWT` authentication.
- Gateway targets, path rules, JWT passthrough, IAM credentials, and Policy Engine `ENFORCE` mode.
- AgentCore Identity workload identities and write-only API key and OAuth2 credential providers.
- Memory strategies, Browser profiles, Code Interpreter, and Managed Harness environments.
- Evaluators, online evaluations, and CloudWatch observability log groups.
- Resource policies and caller-defined least-privilege IAM statements with module resource references.
- Safe module defaults: no FullAccess attachment, wildcard action, CLI mutation, build trigger, or secret output.
- Standard `name`, `create`, and `tags` inputs. Resource names default from the module name and map key.

## Usage

```hcl
module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 1.0"

  name = "customer-support"

  runtimes = {
    primary = {
      role_arn       = aws_iam_role.runtime.arn
      image_uri      = "111122223333.dkr.ecr.us-east-1.amazonaws.com/agent@sha256:..."
      authentication = "AWS_IAM"
    }
  }

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

The module expects immutable ARM64 images and purpose-built IAM roles. It does
not build application containers or attach broad managed policies.

## Examples

- [Basic Runtime](examples/basic): one IAM-authenticated Runtime.
- [Complete governed topology](examples/complete): separate JWT and IAM lanes with Policy, Identity, Memory, Browser, Code Interpreter, and observability.
- [AgentCore Identity](examples/identity): workload identity and write-only OAuth2 credentials.

## Design

The root module is the primary, opinionated entrypoint. Related resources use
maps so callers can create one or many instances without repeated module
blocks. A map item's `name` is optional and defaults to the root `name` plus its
key. Set `create = false` to make the entire module a no-op.

The two nested modules are intentionally isolated provider-gap boundaries:

- `modules/preview` accepts caller-owned CloudFormation for AgentCore features not yet available in the AWS provider.
- `modules/agent-registry-preview` implements shadow-only Agent Registry discovery until a native AWS provider resource is available.

Neither nested module is an authorization source. No other resource is hidden
behind a one-resource wrapper.

## AgentCore Identity

`workload_identities`, `api_key_credential_providers`, and
`oauth2_credential_providers` expose AgentCore Identity directly. Credential
values use AWS provider write-only fields and are never returned. Provider ARNs
are normal identifiers. Supply credentials through your secret-injection
workflow and rotate them by increasing their version input.

Runtime and Gateway workload identity ARNs are also returned in the respective
module outputs.

## Security

- Authentication mode is explicit for every Runtime and Gateway.
- JWT `Authorization` propagation is handled by AgentCore and cannot be added to the custom header allowlist.
- Gateway policy engines are attached in `ENFORCE` mode.
- IAM permission helpers reject wildcard actions and resources.
- API key and OAuth credentials use write-only provider arguments and are never output; only their provider ARNs are exposed.
- Code Interpreter defaults to `SANDBOX`; VPC resources require both subnets and security groups.
- Registry Preview is shadow-only and cannot grant Runtime authority.

## Development

Install the repository's pre-commit hooks, then use the standard OpenTofu
workflow:

```bash
pre-commit install
pre-commit run --all-files
tofu init -backend=false
tofu validate
tofu test
```

CI also validates every example, runs TFLint and Trivy, checks generated
terraform-docs output, and verifies release-note rendering.

## Contributing

Issues and pull requests are welcome. Keep examples executable, document every
public variable and output, and include a mocked OpenTofu test for behavioral
changes.

## License

Apache-2.0 Licensed. See [LICENSE](LICENSE).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.60, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.60, < 7.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_agent_registry_preview"></a> [agent\_registry\_preview](#module\_agent\_registry\_preview) | ./modules/agent-registry-preview | n/a |
| <a name="module_preview"></a> [preview](#module\_preview) | ./modules/preview | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_bedrockagentcore_agent_runtime.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_agent_runtime) | resource |
| [aws_bedrockagentcore_agent_runtime_endpoint.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_agent_runtime_endpoint) | resource |
| [aws_bedrockagentcore_api_key_credential_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_api_key_credential_provider) | resource |
| [aws_bedrockagentcore_browser.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_browser) | resource |
| [aws_bedrockagentcore_browser_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_browser_profile) | resource |
| [aws_bedrockagentcore_code_interpreter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_code_interpreter) | resource |
| [aws_bedrockagentcore_evaluator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_evaluator) | resource |
| [aws_bedrockagentcore_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_gateway) | resource |
| [aws_bedrockagentcore_gateway_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_gateway_rule) | resource |
| [aws_bedrockagentcore_gateway_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_gateway_target) | resource |
| [aws_bedrockagentcore_harness.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_harness) | resource |
| [aws_bedrockagentcore_memory.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_memory) | resource |
| [aws_bedrockagentcore_memory_strategy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_memory_strategy) | resource |
| [aws_bedrockagentcore_oauth2_credential_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_oauth2_credential_provider) | resource |
| [aws_bedrockagentcore_online_evaluation_config.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_online_evaluation_config) | resource |
| [aws_bedrockagentcore_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_policy) | resource |
| [aws_bedrockagentcore_policy_engine.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_policy_engine) | resource |
| [aws_bedrockagentcore_resource_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_resource_policy) | resource |
| [aws_bedrockagentcore_workload_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_workload_identity) | resource |
| [aws_cloudwatch_log_group.observability](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role_policy.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_ssm_parameter.gateway_discovery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_key_credential_providers"></a> [api\_key\_credential\_providers](#input\_api\_key\_credential\_providers) | AgentCore Identity API-key providers. The key is write-only and is never returned by this module. | <pre>map(object({<br/>    name               = optional(string)<br/>    api_key_write_only = string<br/>    secret_version     = number<br/>  }))</pre> | `{}` | no |
| <a name="input_browser_profiles"></a> [browser\_profiles](#input\_browser\_profiles) | Reusable Browser profiles. | <pre>map(object({<br/>    name        = optional(string)<br/>    description = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_browsers"></a> [browsers](#input\_browsers) | AgentCore Browser sandboxes. VPC mode requires subnets and security groups. | <pre>map(object({<br/>    name               = optional(string)<br/>    description        = optional(string)<br/>    execution_role_arn = optional(string)<br/>    network_mode       = optional(string, "PUBLIC")<br/>    security_groups    = optional(set(string), [])<br/>    subnets            = optional(set(string), [])<br/>    browser_signing    = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| <a name="input_code_interpreters"></a> [code\_interpreters](#input\_code\_interpreters) | AgentCore Code Interpreter sandboxes. SANDBOX is the safe no-network default. | <pre>map(object({<br/>    name               = optional(string)<br/>    description        = optional(string)<br/>    execution_role_arn = optional(string)<br/>    network_mode       = optional(string, "SANDBOX")<br/>    security_groups    = optional(set(string), [])<br/>    subnets            = optional(set(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_create"></a> [create](#input\_create) | Controls whether this module creates resources. | `bool` | `true` | no |
| <a name="input_evaluators"></a> [evaluators](#input\_evaluators) | AgentCore evaluators. Configure exactly one of code\_based or llm\_judge. | <pre>map(object({<br/>    name        = optional(string)<br/>    level       = string<br/>    description = optional(string)<br/>    kms_key_arn = optional(string)<br/>    code_based = optional(object({<br/>      lambda_arn      = string<br/>      timeout_seconds = optional(number, 60)<br/>    }))<br/>    llm_judge = optional(object({<br/>      instructions = string<br/>      model_id     = string<br/>      max_tokens   = optional(number, 2048)<br/>      temperature  = optional(number, 0)<br/>      top_p        = optional(number, 1)<br/>      categories = list(object({<br/>        label      = string<br/>        definition = string<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_gateway_discovery_parameters"></a> [gateway\_discovery\_parameters](#input\_gateway\_discovery\_parameters) | SSM parameters that publish generated Gateway URLs without creating Runtime/Gateway dependency cycles. | <pre>map(object({<br/>    gateway_key = string<br/>    name        = string<br/>    description = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_gateway_role_permissions"></a> [gateway\_role\_permissions](#input\_gateway\_role\_permissions) | Least-privilege inline policies attached to caller-owned Gateway roles. | <pre>map(object({<br/>    gateway_key = string<br/>    statements = list(object({<br/>      sid                    = string<br/>      actions                = set(string)<br/>      resources              = optional(set(string), [])<br/>      runtime_keys           = optional(set(string), [])<br/>      api_key_provider_keys  = optional(set(string), [])<br/>      oauth2_credential_keys = optional(set(string), [])<br/>      workload_identity_keys = optional(set(string), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_gateway_rules"></a> [gateway\_rules](#input\_gateway\_rules) | Path rules that route to a named target; optional IAM principals constrain workload routes. | <pre>map(object({<br/>    gateway_key    = string<br/>    priority       = number<br/>    paths          = list(string)<br/>    target_name    = string<br/>    description    = optional(string)<br/>    iam_principals = optional(set(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_gateway_targets"></a> [gateway\_targets](#input\_gateway\_targets) | AgentCore Runtime or MCP-server Gateway targets with one explicit outbound credential mode. | <pre>map(object({<br/>    gateway_key               = string<br/>    name                      = optional(string)<br/>    target_type               = string<br/>    runtime_key               = optional(string)<br/>    runtime_arn               = optional(string)<br/>    qualifier                 = optional(string, "DEFAULT")<br/>    mcp_endpoint              = optional(string)<br/>    mcp_listing_mode          = optional(string)<br/>    credential_mode           = string<br/>    signing_service           = optional(string, "bedrock-agentcore")<br/>    signing_region            = optional(string)<br/>    credential_provider_key   = optional(string)<br/>    credential_provider_arn   = optional(string)<br/>    credential_location       = optional(string, "HEADER")<br/>    credential_parameter_name = optional(string)<br/>    credential_prefix         = optional(string)<br/>    oauth_grant_type          = optional(string)<br/>    oauth_scopes              = optional(set(string), [])<br/>    oauth_default_return_url  = optional(string)<br/>    oauth_custom_parameters   = optional(map(string), {})<br/>    description               = optional(string)<br/>    allowed_query_parameters  = optional(set(string), [])<br/>    allowed_request_headers   = optional(set(string), [])<br/>    allowed_response_headers  = optional(set(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_gateways"></a> [gateways](#input\_gateways) | AgentCore Gateways. An attached policy engine always runs in ENFORCE mode. | <pre>map(object({<br/>    name              = optional(string)<br/>    role_arn          = string<br/>    authentication    = string<br/>    description       = optional(string)<br/>    kms_key_arn       = optional(string)<br/>    exception_level   = optional(string)<br/>    policy_engine_key = optional(string)<br/>    protocol_type     = optional(string)<br/>    jwt = optional(object({<br/>      discovery_url               = string<br/>      allowed_audience            = optional(set(string), [])<br/>      allowed_clients             = optional(set(string), [])<br/>      allowed_scopes              = optional(set(string), [])<br/>      allowed_workload_identities = optional(list(string), [])<br/>      claims = optional(list(object({<br/>        name         = string<br/>        value_type   = string<br/>        operator     = string<br/>        string_value = optional(string)<br/>        string_list  = optional(set(string), [])<br/>      })), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_harnesses"></a> [harnesses](#input\_harnesses) | Managed Harness configurations for non-production experimentation without effect tools. | <pre>map(object({<br/>    name                  = optional(string)<br/>    execution_role_arn    = string<br/>    image_uri             = string<br/>    model_id              = string<br/>    system_prompt         = string<br/>    environment_variables = optional(map(string), {})<br/>    network_mode          = optional(string, "PUBLIC")<br/>    security_groups       = optional(set(string), [])<br/>    subnets               = optional(set(string), [])<br/>    require_s3_endpoint   = optional(bool, false)<br/>    idle_timeout_seconds  = optional(number)<br/>    max_lifetime_seconds  = optional(number)<br/>    allowed_tools         = optional(set(string), [])<br/>    max_iterations        = optional(number, 10)<br/>    max_tokens            = optional(number, 8192)<br/>    timeout_seconds       = optional(number, 900)<br/>    temperature           = optional(number, 0)<br/>    top_p                 = optional(number, 1)<br/>  }))</pre> | `{}` | no |
| <a name="input_memories"></a> [memories](#input\_memories) | AgentCore Memory stores. Namespace content is never an authority source. | <pre>map(object({<br/>    name                      = optional(string)<br/>    event_expiry_duration     = number<br/>    description               = optional(string)<br/>    encryption_key_arn        = optional(string)<br/>    memory_execution_role_arn = optional(string)<br/>    indexed_keys = optional(list(object({<br/>      key  = string<br/>      type = string<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_memory_strategies"></a> [memory\_strategies](#input\_memory\_strategies) | Memory strategies attached to a module-managed Memory. | <pre>map(object({<br/>    memory_key                = string<br/>    name                      = optional(string)<br/>    type                      = string<br/>    description               = optional(string)<br/>    namespaces                = optional(list(string), [])<br/>    namespace_templates       = optional(list(string), [])<br/>    memory_execution_role_arn = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used as the default prefix for module-managed resources. | `string` | n/a | yes |
| <a name="input_oauth2_credential_providers"></a> [oauth2\_credential\_providers](#input\_oauth2\_credential\_providers) | Custom AgentCore Identity OAuth2 providers. Client credentials are write-only and are never returned. | <pre>map(object({<br/>    name                     = optional(string)<br/>    client_id_write_only     = string<br/>    client_secret_write_only = string<br/>    credentials_version      = number<br/>    discovery_url            = optional(string)<br/>    issuer                   = optional(string)<br/>    authorization_endpoint   = optional(string)<br/>    token_endpoint           = optional(string)<br/>    response_types           = optional(set(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_observability"></a> [observability](#input\_observability) | CloudWatch log groups used by AgentCore Observability, evaluations, and sanitized usage telemetry. | <pre>map(object({<br/>    log_group_name    = string<br/>    retention_in_days = optional(number, 365)<br/>    kms_key_arn       = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_online_evaluations"></a> [online\_evaluations](#input\_online\_evaluations) | Online evaluation configs sourcing sanitized AgentCore telemetry from CloudWatch Logs. | <pre>map(object({<br/>    name                    = optional(string)<br/>    execution_role_arn      = string<br/>    evaluator_keys          = set(string)<br/>    log_group_names         = set(string)<br/>    service_names           = set(string)<br/>    sampling_percentage     = number<br/>    session_timeout_minutes = number<br/>    enable_on_create        = optional(bool, true)<br/>    description             = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | Cedar policies, normally generated tool-by-tool from the caller's security catalog. | <pre>map(object({<br/>    engine_key = string<br/>    name       = optional(string)<br/>    statement  = optional(string)<br/>    scoped = optional(object({<br/>      gateway_key    = string<br/>      principal_type = string<br/>      action_id      = string<br/>      condition      = optional(string)<br/>    }))<br/>    description     = optional(string)<br/>    validation_mode = optional(string, "FAIL_ON_ANY_FINDINGS")<br/>  }))</pre> | `{}` | no |
| <a name="input_policy_engines"></a> [policy\_engines](#input\_policy\_engines) | AgentCore Cedar policy engines. | <pre>map(object({<br/>    name               = optional(string)<br/>    description        = optional(string)<br/>    encryption_key_arn = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_preview_stacks"></a> [preview\_stacks](#input\_preview\_stacks) | Isolated CloudFormation stacks for AgentCore Preview resources absent from the AWS provider. Templates must reference secrets externally. | <pre>map(object({<br/>    name          = optional(string)<br/>    template_body = string<br/>    parameters    = optional(map(string), {})<br/>    capabilities  = optional(set(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_registries"></a> [registries](#input\_registries) | AWS Agent Registry Preview catalogs in the current agent-registry namespace, isolated behind CloudFormation until the AWS provider exposes a native resource. | <pre>map(object({<br/>    name               = optional(string)<br/>    log_retention_days = optional(number, 365)<br/>  }))</pre> | `{}` | no |
| <a name="input_resource_policies"></a> [resource\_policies](#input\_resource\_policies) | Resource policies for runtimes, gateways, and other AgentCore resources. | <pre>map(object({<br/>    resource_arn  = optional(string)<br/>    resource_type = optional(string)<br/>    resource_key  = optional(string)<br/>    policy        = optional(string)<br/>    principals    = optional(set(string), [])<br/>    actions       = optional(set(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_runtime_endpoints"></a> [runtime\_endpoints](#input\_runtime\_endpoints) | Named immutable Runtime endpoints. | <pre>map(object({<br/>    runtime_key     = string<br/>    name            = optional(string)<br/>    description     = optional(string)<br/>    runtime_version = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_runtime_role_permissions"></a> [runtime\_role\_permissions](#input\_runtime\_role\_permissions) | Least-privilege inline policies attached to caller-owned Runtime roles, with module resource references resolved without cycles. | <pre>map(object({<br/>    runtime_key = string<br/>    statements = list(object({<br/>      sid                    = string<br/>      actions                = set(string)<br/>      resources              = optional(set(string), [])<br/>      gateway_keys           = optional(set(string), [])<br/>      memory_keys            = optional(set(string), [])<br/>      code_interpreter_keys  = optional(set(string), [])<br/>      browser_keys           = optional(set(string), [])<br/>      gateway_parameter_keys = optional(set(string), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_runtimes"></a> [runtimes](#input\_runtimes) | AgentCore Runtimes. Authentication is explicit per runtime; CUSTOM\_JWT and AWS\_IAM cannot be combined. | <pre>map(object({<br/>    name                            = optional(string)<br/>    role_arn                        = string<br/>    image_uri                       = string<br/>    authentication                  = string<br/>    description                     = optional(string)<br/>    environment_variables           = optional(map(string), {})<br/>    gateway_url_environment         = optional(map(string), {})<br/>    memory_id_environment           = optional(map(string), {})<br/>    browser_id_environment          = optional(map(string), {})<br/>    browser_profile_id_environment  = optional(map(string), {})<br/>    code_interpreter_id_environment = optional(map(string), {})<br/>    network_mode                    = optional(string, "PUBLIC")<br/>    security_groups                 = optional(set(string), [])<br/>    subnets                         = optional(set(string), [])<br/>    server_protocol                 = optional(string, "HTTP")<br/>    request_headers                 = optional(set(string), [])<br/>    idle_timeout_seconds            = optional(number, 900)<br/>    max_lifetime_seconds            = optional(number, 28800)<br/>    jwt = optional(object({<br/>      discovery_url               = string<br/>      allowed_audience            = optional(set(string), [])<br/>      allowed_clients             = optional(set(string), [])<br/>      allowed_scopes              = optional(set(string), [])<br/>      allowed_gateway_arn         = optional(string)<br/>      allowed_gateway_key         = optional(string)<br/>      allowed_workload_identities = optional(list(string), [])<br/>      claims = optional(list(object({<br/>        name         = string<br/>        value_type   = string<br/>        operator     = string<br/>        string_value = optional(string)<br/>        string_list  = optional(set(string), [])<br/>      })), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to every taggable resource. | `map(string)` | `{}` | no |
| <a name="input_workload_identities"></a> [workload\_identities](#input\_workload\_identities) | AgentCore workload identities for outbound authentication. | <pre>map(object({<br/>    name                      = optional(string)<br/>    allowed_oauth_return_urls = optional(set(string), [])<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_key_credential_providers"></a> [api\_key\_credential\_providers](#output\_api\_key\_credential\_providers) | AgentCore API-key credential provider ARNs keyed by caller key. |
| <a name="output_browser_profiles"></a> [browser\_profiles](#output\_browser\_profiles) | AgentCore Browser Profile identifiers and ARNs keyed by caller key. |
| <a name="output_browsers"></a> [browsers](#output\_browsers) | AgentCore Browser identifiers and ARNs keyed by caller key. |
| <a name="output_code_interpreters"></a> [code\_interpreters](#output\_code\_interpreters) | AgentCore Code Interpreter identifiers and ARNs keyed by caller key. |
| <a name="output_evaluators"></a> [evaluators](#output\_evaluators) | AgentCore Evaluator identifiers and ARNs keyed by caller key. |
| <a name="output_gateway_discovery_parameters"></a> [gateway\_discovery\_parameters](#output\_gateway\_discovery\_parameters) | SSM parameter names and ARNs that publish Gateway URLs. |
| <a name="output_gateway_rules"></a> [gateway\_rules](#output\_gateway\_rules) | Gateway rule identifiers keyed by caller key. |
| <a name="output_gateway_targets"></a> [gateway\_targets](#output\_gateway\_targets) | Gateway target identifiers keyed by caller key. |
| <a name="output_gateways"></a> [gateways](#output\_gateways) | Gateway identifiers and invocation URLs keyed by caller key. |
| <a name="output_harnesses"></a> [harnesses](#output\_harnesses) | AgentCore Harness identifiers and ARNs keyed by caller key. |
| <a name="output_memories"></a> [memories](#output\_memories) | AgentCore Memory identifiers and ARNs keyed by caller key. |
| <a name="output_memory_strategies"></a> [memory\_strategies](#output\_memory\_strategies) | AgentCore Memory strategy identifiers keyed by caller key. |
| <a name="output_oauth2_credential_providers"></a> [oauth2\_credential\_providers](#output\_oauth2\_credential\_providers) | AgentCore OAuth2 credential provider ARNs keyed by caller key. |
| <a name="output_observability_log_groups"></a> [observability\_log\_groups](#output\_observability\_log\_groups) | CloudWatch observability log group ARNs keyed by caller key. |
| <a name="output_online_evaluations"></a> [online\_evaluations](#output\_online\_evaluations) | AgentCore online evaluation identifiers and ARNs keyed by caller key. |
| <a name="output_policies"></a> [policies](#output\_policies) | AgentCore Cedar policy identifiers and ARNs keyed by caller key. |
| <a name="output_policy_engines"></a> [policy\_engines](#output\_policy\_engines) | AgentCore Policy Engine identifiers and ARNs keyed by caller key. |
| <a name="output_preview_stacks"></a> [preview\_stacks](#output\_preview\_stacks) | Isolated preview CloudFormation stack identifiers and outputs keyed by caller key. |
| <a name="output_registries"></a> [registries](#output\_registries) | Shadow Agent Registry Preview identifiers and ARNs keyed by caller key. |
| <a name="output_runtime_endpoints"></a> [runtime\_endpoints](#output\_runtime\_endpoints) | Runtime endpoint ARNs keyed by caller key. |
| <a name="output_runtimes"></a> [runtimes](#output\_runtimes) | Runtime IDs, ARNs, versions, and workload identities keyed by caller key. |
| <a name="output_workload_identities"></a> [workload\_identities](#output\_workload\_identities) | AgentCore workload identity ARNs keyed by caller key. |
<!-- END_TF_DOCS -->
