# Versioned Gateway connector target

Creates a Web Search connector target on an existing AgentCore Gateway and pins connector version `1.2.0`. Target-level domain filters are enforced by AgentCore and cannot be relaxed by request-level filters.

The Gateway execution role must separately allow `bedrock-agentcore:InvokeWebSearch` on `arn:aws:bedrock-agentcore:<region>:aws:tool/web-search.v1`. This example does not modify the role of an existing Gateway.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_web_search"></a> [web\_search](#module\_web\_search) | ../../modules/gateway-connector-target | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_domains"></a> [allowed\_domains](#input\_allowed\_domains) | Administrator allowlist enforced by the Web Search target. | `list(string)` | <pre>[<br/>  "docs.aws.amazon.com",<br/>  "aws.amazon.com"<br/>]</pre> | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region containing the AgentCore Gateway. | `string` | `"us-east-1"` | no |
| <a name="input_excluded_domains"></a> [excluded\_domains](#input\_excluded\_domains) | Administrator denylist enforced by the Web Search target. | `list(string)` | `[]` | no |
| <a name="input_gateway_identifier"></a> [gateway\_identifier](#input\_gateway\_identifier) | Existing AgentCore Gateway ID. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_connector_version"></a> [connector\_version](#output\_connector\_version) | Pinned Web Search connector version. |
| <a name="output_target_id"></a> [target\_id](#output\_target\_id) | Created Web Search Gateway target ID. |
<!-- END_TF_DOCS -->
