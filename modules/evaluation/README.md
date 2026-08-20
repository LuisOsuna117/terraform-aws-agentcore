# AgentCore Evaluation submodule

Creates code-based or LLM-as-judge Evaluators and optional online evaluation configurations. Sampling, source log groups, and execution roles are explicit caller inputs.

Use the focused example at [`examples/evaluation`](../../examples/evaluation).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.61 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.61 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_bedrockagentcore_evaluator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_evaluator) | resource |
| [aws_bedrockagentcore_online_evaluation_config.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_online_evaluation_config) | resource |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_evaluators"></a> [evaluators](#input\_evaluators) | AgentCore Evaluators. Configure exactly one of code\_based or llm\_judge. | <pre>map(object({<br/>    name        = optional(string)<br/>    level       = string<br/>    description = optional(string)<br/>    kms_key_arn = optional(string)<br/>    region      = optional(string)<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      update = optional(string)<br/>      delete = optional(string)<br/>    }))<br/>    code_based = optional(object({<br/>      lambda_arn      = string<br/>      timeout_seconds = optional(number, 60)<br/>    }))<br/>    llm_judge = optional(object({<br/>      instructions                    = string<br/>      model_id                        = string<br/>      max_tokens                      = optional(number, 2048)<br/>      temperature                     = optional(number, 0)<br/>      top_p                           = optional(number, 1)<br/>      additional_model_request_fields = optional(string)<br/>      stop_sequences                  = optional(list(string), [])<br/>      categories = optional(list(object({<br/>        label      = string<br/>        definition = string<br/>      })), [])<br/>      numerical = optional(list(object({<br/>        label      = string<br/>        definition = string<br/>        value      = number<br/>      })), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name for Evaluator and online evaluation resources. | `string` | n/a | yes |
| <a name="input_online_evaluations"></a> [online\_evaluations](#input\_online\_evaluations) | Online evaluation configs sourcing AgentCore telemetry from CloudWatch Logs. | <pre>map(object({<br/>    name                    = optional(string)<br/>    description             = optional(string)<br/>    execution_role_arn      = string<br/>    evaluator_keys          = optional(set(string), [])<br/>    evaluator_ids           = optional(set(string), [])<br/>    log_group_names         = set(string)<br/>    service_names           = set(string)<br/>    sampling_percentage     = number<br/>    session_timeout_minutes = number<br/>    enable_on_create        = optional(bool, true)<br/>    region                  = optional(string)<br/>    filters = optional(list(object({<br/>      key      = string<br/>      operator = string<br/>      value = object({<br/>        boolean_value = optional(bool)<br/>        double_value  = optional(number)<br/>        string_value  = optional(string)<br/>      })<br/>    })), [])<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      update = optional(string)<br/>      delete = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to evaluation resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_evaluators"></a> [evaluators](#output\_evaluators) | Evaluator IDs and ARNs keyed by caller-defined name. |
| <a name="output_online_evaluations"></a> [online\_evaluations](#output\_online\_evaluations) | Online evaluation IDs and ARNs keyed by caller-defined name. |
<!-- END_TF_DOCS -->
