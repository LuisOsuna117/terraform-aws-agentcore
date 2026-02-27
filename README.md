# terraform-aws-agentcore

> **Community module** — not affiliated with or endorsed by AWS.
> Published on the [Terraform Registry](https://registry.terraform.io/modules/LuisOsuna117/agentcore/aws) and the [OpenTofu Registry](https://search.opentofu.org/module/LuisOsuna117/agentcore/aws). Compatible with both **Terraform ≥ 1.8** and **OpenTofu ≥ 1.8**.

A Terraform / OpenTofu module that provisions [Amazon Bedrock AgentCore](https://docs.aws.amazon.com/bedrock/latest/userguide/agentcore.html) resources on AWS, together with the supporting infrastructure needed to build and deploy containerised agents.

**Easy to start, extensible for production.** One required variable (`name`) gets a working runtime. A set of clearly named `create_*` boolean flags let you opt-in to additional resources — without forking the module or fighting the abstractions.

---

## 🚀 Quickstart

```hcl
module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 0.3"

  name = "my-agent"
}
```

Add a `Dockerfile` and your agent code under `./agent-code/`, then run `terraform apply` (or `tofu apply`). That's it.

---

## ✅ Features

- ✅ **Single required variable** — only `name` is mandatory; every other input has a safe default.
- 🐳 **Bring Your Own Image (BYO)** — set `create_build_pipeline = false` and pass `image_uri` to skip the CodeBuild pipeline entirely.
- ⚙️ **Decoupled build trigger** — set `trigger_build_on_apply = false` to manage CodeBuild runs from your own CI/CD pipeline.
- 🛰️ **Runtime toggle** — set `create_runtime = false` to provision only the build infrastructure while the AgentCore runtime is not yet needed.
- 🧠 **Memory resource** — set `create_memory = true` to provision an `aws_bedrockagentcore_memory` resource alongside the AgentCore runtime.
- 🌐 **Gateway resource** — set `create_gateway = true` to provision an `aws_bedrockagentcore_gateway` with JWT or AWS IAM auth, MCP protocol, and optional Lambda interceptors (max 2, via `gateway_interceptor_configurations`).
- 🔒 **Execution role escape hatch** — bring your own IAM role or let the module create one.
- 🔒 **Extensible IAM** — append policy statements to the execution role via `additional_iam_statements` without touching the module source.
- 📦 **Content-addressed source uploads** — S3 object keys include the archive MD5, so CodeBuild is only re-triggered when agent code actually changes.
- 🏷️ **Consistent tagging** — a `tags` map is merged onto every taggable resource alongside module-managed defaults.
- ✅ **Validated inputs** — naming patterns, enum values, and numeric bounds are enforced by `validation` blocks before any plan is generated.

---

## 🧱 Module structure

```
.
├── main.tf          # Root wrapper — orchestrates all submodules
├── variables.tf
├── outputs.tf
├── versions.tf
└── modules/
    ├── build/       # ECR + S3 + CodeBuild + IAM (create_build_pipeline = true)
    ├── runtime/     # aws_bedrockagentcore_agent_runtime
    ├── memory/      # aws_bedrockagentcore_memory (create_memory = true)
    └── gateway/     # aws_bedrockagentcore_gateway (create_gateway = true)
```

Each submodule under `modules/` can also be called independently if you only need a subset of resources.

---

## 🧩 What this module creates

Resources marked with a condition are only created when the corresponding flag is `true`.

| Resource | Condition | Purpose |
|---|---|---|
| `aws_iam_role` (execution) | `create_execution_role` | Runtime execution role assumed by the AgentCore service. |
| `aws_iam_role_policy` (execution) | `create_execution_role` | Least-privilege inline policy: ECR pull, CloudWatch Logs, X-Ray, Metrics, Bedrock, workload tokens. |
| `aws_iam_role_policy_attachment` | `create_execution_role && attach_bedrock_fullaccess_policy` | Optional `BedrockAgentCoreFullAccess` managed policy attachment. |
| `aws_bedrockagentcore_agent_runtime` | `create_runtime` | The AgentCore runtime that executes your agent container. |
| `aws_ecr_repository` + policies | `create_build_pipeline` | Private container registry for agent images. |
| `aws_codebuild_project` | `create_build_pipeline` | Builds the agent Docker image and pushes it to ECR. |
| `aws_iam_role` (codebuild) | `create_build_pipeline` | Service role for the CodeBuild pipeline. |
| `aws_s3_bucket` + config | `create_build_pipeline` | Private versioned bucket for agent source code. |
| `aws_s3_object` | `create_build_pipeline` | Content-addressed archive of your agent source directory. |
| `null_resource` (build trigger) | `create_build_pipeline && trigger_build_on_apply` | Triggers a CodeBuild run on every apply when source code changes. |
| `aws_bedrockagentcore_memory` | `create_memory` | Persistent memory store for your agent. |
| `aws_bedrockagentcore_gateway` | `create_gateway` | MCP gateway endpoint with configurable auth and interceptors. |
| `aws_iam_role` (gateway) | `create_gateway && gateway_create_role` | Execution role for the gateway resource. |

## 🚫 What this module does NOT create

- **VPC, subnets, or security groups** — required when using `network_mode = "PRIVATE"`, but out of scope for this module.
- **Bedrock model access** — enable foundation model access separately in the AWS console.
- **KMS keys** — S3 and ECR use AWS-managed encryption by default. Pass `gateway_kms_key_arn` or `memory_encryption_key_arn` to use customer-managed keys you manage outside of this module.

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.21 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.21 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_build"></a> [build](#module\_build) | ./modules/build | n/a |
| <a name="module_gateway"></a> [gateway](#module\_gateway) | ./modules/gateway | n/a |
| <a name="module_memory"></a> [memory](#module\_memory) | ./modules/memory | n/a |
| <a name="module_runtime"></a> [runtime](#module\_runtime) | ./modules/runtime | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.agent_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.agent_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.agent_execution_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_iam_statements"></a> [additional\_iam\_statements](#input\_additional\_iam\_statements) | Additional IAM policy statements to append to the inline policy on the execution role. Use this to grant access to Bedrock models, Secrets Manager, or other services your agent code requires. | `list(any)` | `[]` | no |
| <a name="input_agent_source_dir"></a> [agent\_source\_dir](#input\_agent\_source\_dir) | Absolute or module-relative path to the directory containing your agent application code. The directory is zipped and uploaded to S3 for CodeBuild to consume. | `string` | `null` | no |
| <a name="input_attach_bedrock_fullaccess_policy"></a> [attach\_bedrock\_fullaccess\_policy](#input\_attach\_bedrock\_fullaccess\_policy) | When true and create\_execution\_role = true, attaches the AWS-managed BedrockAgentCoreFullAccess policy to the execution role. Set to false if you prefer a least-privilege-only setup via additional\_iam\_statements. | `bool` | `true` | no |
| <a name="input_codebuild_build_timeout"></a> [codebuild\_build\_timeout](#input\_codebuild\_build\_timeout) | Maximum duration (in minutes) for a CodeBuild build before it is terminated. | `number` | `60` | no |
| <a name="input_codebuild_compute_type"></a> [codebuild\_compute\_type](#input\_codebuild\_compute\_type) | Compute type for the CodeBuild environment. See https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html | `string` | `"BUILD_GENERAL1_LARGE"` | no |
| <a name="input_codebuild_environment_image"></a> [codebuild\_environment\_image](#input\_codebuild\_environment\_image) | Docker image used for the CodeBuild build environment. | `string` | `"aws/codebuild/amazonlinux2-aarch64-standard:3.0"` | no |
| <a name="input_codebuild_environment_type"></a> [codebuild\_environment\_type](#input\_codebuild\_environment\_type) | CodeBuild environment type. Should match the architecture of codebuild\_environment\_image (e.g. ARM\_CONTAINER for aarch64 images). | `string` | `"ARM_CONTAINER"` | no |
| <a name="input_create_build_pipeline"></a> [create\_build\_pipeline](#input\_create\_build\_pipeline) | When true (default), creates the full CodeBuild build pipeline: ECR repository, S3 source bucket, and CodeBuild project. Set to false to use a pre-built image via image\_uri (Bring Your Own Image). | `bool` | `true` | no |
| <a name="input_create_execution_role"></a> [create\_execution\_role](#input\_create\_execution\_role) | When true, the module creates an IAM execution role for the AgentCore runtime. Set to false to provide an existing role via execution\_role\_arn. | `bool` | `true` | no |
| <a name="input_create_gateway"></a> [create\_gateway](#input\_create\_gateway) | When true, creates an AgentCore Gateway resource using modules/gateway. Defaults to false. | `bool` | `false` | no |
| <a name="input_create_memory"></a> [create\_memory](#input\_create\_memory) | When true, creates an AgentCore Memory resource using modules/memory. Defaults to false. | `bool` | `false` | no |
| <a name="input_create_runtime"></a> [create\_runtime](#input\_create\_runtime) | When true (default), creates the AgentCore runtime resource. Set to false to provision only the build pipeline infrastructure without a runtime (useful for pre-baking images before the runtime is ready). | `bool` | `true` | no |
| <a name="input_description"></a> [description](#input\_description) | Human-readable description attached to the AgentCore runtime resource. | `string` | `"Managed by terraform-aws-agentcore."` | no |
| <a name="input_ecr_force_delete"></a> [ecr\_force\_delete](#input\_ecr\_force\_delete) | Allow the ECR repository to be deleted even if it contains images. Useful in non-production environments. Defaults to false for safety. | `bool` | `false` | no |
| <a name="input_ecr_image_tag_mutability"></a> [ecr\_image\_tag\_mutability](#input\_ecr\_image\_tag\_mutability) | Tag mutability setting for the ECR repository. IMMUTABLE is recommended for production to prevent image overwrites. | `string` | `"MUTABLE"` | no |
| <a name="input_ecr_lifecycle_keep_count"></a> [ecr\_lifecycle\_keep\_count](#input\_ecr\_lifecycle\_keep\_count) | Number of most-recent images to retain in the ECR repository. Older images are expired automatically. | `number` | `10` | no |
| <a name="input_ecr_repository_name"></a> [ecr\_repository\_name](#input\_ecr\_repository\_name) | Name of the ECR repository that holds agent container images. Defaults to var.name when null. | `string` | `null` | no |
| <a name="input_ecr_scan_on_push"></a> [ecr\_scan\_on\_push](#input\_ecr\_scan\_on\_push) | Enable automatic vulnerability scanning when an image is pushed to the ECR repository. | `bool` | `true` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Additional environment variables injected into the AgentCore runtime process. AWS\_REGION and AWS\_DEFAULT\_REGION are always set automatically. | `map(string)` | `{}` | no |
| <a name="input_execution_role_arn"></a> [execution\_role\_arn](#input\_execution\_role\_arn) | ARN of an existing IAM role to use as the AgentCore runtime execution role. Required when create\_execution\_role = false. | `string` | `null` | no |
| <a name="input_gateway_authorizer_configuration"></a> [gateway\_authorizer\_configuration](#input\_gateway\_authorizer\_configuration) | JWT authorizer configuration. Required when gateway\_authorizer\_type = "CUSTOM\_JWT". Shape: { discovery\_url, allowed\_audience, allowed\_clients }. | <pre>object({<br/>    discovery_url    = string<br/>    allowed_audience = optional(list(string), [])<br/>    allowed_clients  = optional(list(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_gateway_authorizer_type"></a> [gateway\_authorizer\_type](#input\_gateway\_authorizer\_type) | Gateway request authorizer type. "CUSTOM\_JWT" requires gateway\_authorizer\_configuration. "AWS\_IAM" uses SigV4. | `string` | `"AWS_IAM"` | no |
| <a name="input_gateway_create_role"></a> [gateway\_create\_role](#input\_gateway\_create\_role) | When true, the gateway module creates an IAM role. Set to false and supply gateway\_role\_arn to reuse an existing role. | `bool` | `true` | no |
| <a name="input_gateway_description"></a> [gateway\_description](#input\_gateway\_description) | Human-readable description for the Gateway resource. | `string` | `null` | no |
| <a name="input_gateway_exception_level"></a> [gateway\_exception\_level](#input\_gateway\_exception\_level) | Exception detail level exposed via the gateway. Valid values: INFO, WARN, ERROR. | `string` | `null` | no |
| <a name="input_gateway_interceptor_configurations"></a> [gateway\_interceptor\_configurations](#input\_gateway\_interceptor\_configurations) | List of interceptor configurations (max 2). Each: { interception\_points, lambda\_arn, pass\_request\_headers }. | <pre>list(object({<br/>    interception_points  = list(string)<br/>    lambda_arn           = string<br/>    pass_request_headers = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_gateway_kms_key_arn"></a> [gateway\_kms\_key\_arn](#input\_gateway\_kms\_key\_arn) | ARN of the KMS key used to encrypt gateway data. When null, AWS-managed encryption is used. | `string` | `null` | no |
| <a name="input_gateway_name"></a> [gateway\_name](#input\_gateway\_name) | Name for the AgentCore Gateway resource. Defaults to var.name when null. | `string` | `null` | no |
| <a name="input_gateway_protocol_configuration"></a> [gateway\_protocol\_configuration](#input\_gateway\_protocol\_configuration) | MCP protocol configuration. Shape: { instructions, search\_type, supported\_versions }. | <pre>object({<br/>    instructions       = optional(string)<br/>    search_type        = optional(string)<br/>    supported_versions = optional(list(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_gateway_protocol_type"></a> [gateway\_protocol\_type](#input\_gateway\_protocol\_type) | Protocol type for the gateway. Currently only "MCP" is supported. | `string` | `"MCP"` | no |
| <a name="input_gateway_role_arn"></a> [gateway\_role\_arn](#input\_gateway\_role\_arn) | ARN of an existing IAM role for the gateway. Required when gateway\_create\_role = false. | `string` | `null` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Docker image tag to deploy to the AgentCore runtime. Used as the tag appended to the ECR image URI in codebuild mode. Changing this triggers a new CodeBuild run when trigger\_build\_on\_apply = true. | `string` | `"latest"` | no |
| <a name="input_image_uri"></a> [image\_uri](#input\_image\_uri) | Full container image URI (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-agent:v1.2.3) to deploy to the runtime. Required when create\_build\_pipeline = false. Must be null when create\_build\_pipeline = true. | `string` | `null` | no |
| <a name="input_memory_description"></a> [memory\_description](#input\_memory\_description) | Human-readable description for the Memory resource. | `string` | `null` | no |
| <a name="input_memory_encryption_key_arn"></a> [memory\_encryption\_key\_arn](#input\_memory\_encryption\_key\_arn) | ARN of the KMS key used to encrypt memory data. When null, AWS-managed encryption is used. | `string` | `null` | no |
| <a name="input_memory_event_expiry_duration"></a> [memory\_event\_expiry\_duration](#input\_memory\_event\_expiry\_duration) | Number of days after which memory events expire (7–365). Required when create\_memory = true. Defaults to 90. | `number` | `90` | no |
| <a name="input_memory_execution_role_arn"></a> [memory\_execution\_role\_arn](#input\_memory\_execution\_role\_arn) | ARN of the IAM role the memory service assumes. When null, the default service role is used. | `string` | `null` | no |
| <a name="input_memory_name"></a> [memory\_name](#input\_memory\_name) | Name for the AgentCore Memory resource. Defaults to var.name when null. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name used as a prefix for all resources created by this module (e.g. "my-agent"). Must start with a letter, max 32 characters. | `string` | n/a | yes |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | Network mode for the AgentCore runtime. PUBLIC exposes the runtime endpoint on the public internet; PRIVATE keeps it internal to your VPC. | `string` | `"PUBLIC"` | no |
| <a name="input_runtime_name"></a> [runtime\_name](#input\_runtime\_name) | Override for the AgentCore runtime resource name. Defaults to var.name when null. Hyphens are automatically converted to underscores to satisfy the AgentCore API. | `string` | `null` | no |
| <a name="input_source_bucket_force_destroy"></a> [source\_bucket\_force\_destroy](#input\_source\_bucket\_force\_destroy) | Allow the S3 source bucket to be destroyed even if it contains objects. Useful in non-production environments. Defaults to false for safety. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all taggable resources. Merged with module-level defaults. | `map(string)` | `{}` | no |
| <a name="input_trigger_build_on_apply"></a> [trigger\_build\_on\_apply](#input\_trigger\_build\_on\_apply) | When true (default) and create\_build\_pipeline = true, a CodeBuild run is automatically started on every apply where source code, image\_tag, or ECR configuration changes. Set to false to manage builds out-of-band (CI/CD pipeline, manual console run). Ignored when create\_build\_pipeline = false. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agent_runtime_arn"></a> [agent\_runtime\_arn](#output\_agent\_runtime\_arn) | ARN of the AgentCore runtime. Use this to grant invoke permissions to callers. Null when create\_runtime = false. |
| <a name="output_agent_runtime_id"></a> [agent\_runtime\_id](#output\_agent\_runtime\_id) | ID of the AgentCore runtime resource. Null when create\_runtime = false. |
| <a name="output_agent_runtime_name"></a> [agent\_runtime\_name](#output\_agent\_runtime\_name) | Resolved name of the AgentCore runtime as registered with the Bedrock AgentCore API. Null when create\_runtime = false. |
| <a name="output_agent_runtime_network_mode"></a> [agent\_runtime\_network\_mode](#output\_agent\_runtime\_network\_mode) | Network mode of the runtime (PUBLIC or PRIVATE). Null when create\_runtime = false. |
| <a name="output_agent_runtime_version"></a> [agent\_runtime\_version](#output\_agent\_runtime\_version) | Version identifier of the deployed AgentCore runtime. Null when create\_runtime = false. |
| <a name="output_codebuild_project_arn"></a> [codebuild\_project\_arn](#output\_codebuild\_project\_arn) | ARN of the CodeBuild project. Null when create\_build\_pipeline = false. |
| <a name="output_codebuild_project_name"></a> [codebuild\_project\_name](#output\_codebuild\_project\_name) | Name of the CodeBuild project. Null when create\_build\_pipeline = false. |
| <a name="output_codebuild_role_arn"></a> [codebuild\_role\_arn](#output\_codebuild\_role\_arn) | ARN of the IAM role used by the CodeBuild image-build project. Null when create\_build\_pipeline = false. |
| <a name="output_container_image_uri"></a> [container\_image\_uri](#output\_container\_image\_uri) | Alias for effective\_image\_uri. Kept for backwards compatibility. |
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | ARN of the ECR repository. Null when create\_build\_pipeline = false. |
| <a name="output_ecr_repository_name"></a> [ecr\_repository\_name](#output\_ecr\_repository\_name) | Name of the ECR repository. Null when create\_build\_pipeline = false. |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | Full ECR repository URL (without tag). Null when create\_build\_pipeline = false. |
| <a name="output_effective_image_uri"></a> [effective\_image\_uri](#output\_effective\_image\_uri) | The container image URI used by the runtime. When create\_build\_pipeline = true this is the ECR repo URL + image\_tag; when create\_build\_pipeline = false this is the caller-supplied image\_uri. |
| <a name="output_execution_role_arn"></a> [execution\_role\_arn](#output\_execution\_role\_arn) | ARN of the IAM role used by the AgentCore runtime. Will equal var.execution\_role\_arn when create\_execution\_role = false. |
| <a name="output_execution_role_name"></a> [execution\_role\_name](#output\_execution\_role\_name) | Name of the module-created execution role. Empty string when create\_execution\_role = false. |
| <a name="output_gateway_arn"></a> [gateway\_arn](#output\_gateway\_arn) | ARN of the AgentCore Gateway. Null when create\_gateway = false. |
| <a name="output_gateway_id"></a> [gateway\_id](#output\_gateway\_id) | Unique identifier of the AgentCore Gateway. Null when create\_gateway = false. |
| <a name="output_gateway_role_arn"></a> [gateway\_role\_arn](#output\_gateway\_role\_arn) | ARN of the IAM role used by the gateway. Null when create\_gateway = false. |
| <a name="output_gateway_role_name"></a> [gateway\_role\_name](#output\_gateway\_role\_name) | Name of the module-created gateway IAM role. Null when create\_gateway = false. |
| <a name="output_gateway_url"></a> [gateway\_url](#output\_gateway\_url) | URL endpoint of the AgentCore Gateway. Null when create\_gateway = false. |
| <a name="output_gateway_workload_identity_arn"></a> [gateway\_workload\_identity\_arn](#output\_gateway\_workload\_identity\_arn) | Workload identity ARN associated with the gateway. Null when create\_gateway = false. |
| <a name="output_memory_arn"></a> [memory\_arn](#output\_memory\_arn) | ARN of the AgentCore Memory resource. Null when create\_memory = false. |
| <a name="output_memory_id"></a> [memory\_id](#output\_memory\_id) | Unique identifier of the AgentCore Memory resource. Null when create\_memory = false. |
| <a name="output_memory_name"></a> [memory\_name](#output\_memory\_name) | Name of the AgentCore Memory resource. Null when create\_memory = false. |
| <a name="output_source_bucket_arn"></a> [source\_bucket\_arn](#output\_source\_bucket\_arn) | ARN of the S3 source bucket. Null when create\_build\_pipeline = false. |
| <a name="output_source_bucket_name"></a> [source\_bucket\_name](#output\_source\_bucket\_name) | Name of the S3 bucket holding the agent source code archive. Null when create\_build\_pipeline = false. |
<!-- END_TF_DOCS -->

---

## 🧪 Examples

| Example | Description |
|---|---|
| [examples/basic](examples/basic) | Minimal runtime — one module call with sensible defaults and a working Python agent stub. |
| [examples/byo-image](examples/byo-image) | Bring Your Own Image — skips the build pipeline and deploys a pre-built image URI. |
| [examples/codebuild-no-trigger](examples/codebuild-no-trigger) | CodeBuild pipeline provisioned but builds are driven by your own CI/CD, not by `apply`. |

---

## 🧰 Usage

### Minimal (CodeBuild + runtime)

```hcl
provider "aws" {
  region = "us-east-1"
}

module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 0.3"

  name = "my-agent"
}
```

Place your agent code (including a `Dockerfile`) in `./agent-code/` relative to where you call the module, then run `terraform apply` (or `tofu apply`). The module zips the directory, uploads it to S3, triggers a CodeBuild build, and provisions the AgentCore runtime.

### Bring Your Own Image

Skip the build pipeline and deploy any container image you have already pushed:

```hcl
module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 0.3"

  name                  = "my-agent"
  create_build_pipeline = false
  image_uri             = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-agent:v1.2.3"
}
```

> **Note:** When `create_build_pipeline = false`, no ECR repository, S3 bucket, or CodeBuild project is created. `image_uri` is passed to the AgentCore runtime as-is. Ensure the execution role has permission to pull from the target registry.

### Decouple builds from apply

Provision the build infrastructure but let your CI pipeline drive actual builds:

```hcl
module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 0.3"

  name                   = "my-agent"
  trigger_build_on_apply = false
}
```

After apply, trigger a build manually:

```bash
aws codebuild start-build --project-name <codebuild_project_name>
```

### Add a Memory store

```hcl
module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 0.3"

  name          = "my-agent"
  create_memory = true

  memory_event_expiry_duration = 30
}
```

### Add a Gateway

```hcl
module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 0.3"

  name           = "my-agent"
  create_gateway = true

  gateway_authorizer_type = "CUSTOM_JWT"
  gateway_authorizer_configuration = {
    discovery_url    = "https://auth.example.com/.well-known/openid-configuration"
    allowed_audience = ["my-agent-api"]
  }
}
```

### Custom source directory and pinned image tag

```hcl
module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 0.3"

  name             = "my-agent"
  agent_source_dir = "${path.root}/src/my-agent"
  image_tag        = "1.2.0"
}
```

### Production configuration

```hcl
module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 0.3"

  name        = "payments-agent"
  description = "Payments processing agent — production."
  image_tag   = var.release_tag

  # Keep the runtime off the public internet
  network_mode = "PRIVATE"

  # Tighten ECR for production
  ecr_image_tag_mutability    = "IMMUTABLE"
  ecr_lifecycle_keep_count    = 30
  ecr_force_delete            = false
  source_bucket_force_destroy = false

  # Drop the broad managed policy; grant only what the agent needs
  attach_bedrock_fullaccess_policy = false
  additional_iam_statements = [
    {
      Sid    = "ClaudeAccess"
      Effect = "Allow"
      Action = [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
      ]
      Resource = "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0"
    },
    {
      Sid      = "SecretsAccess"
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = "arn:aws:secretsmanager:us-east-1:123456789012:secret:payments-agent/*"
    },
  ]

  codebuild_compute_type = "BUILD_GENERAL1_XLARGE"

  tags = {
    Environment = "production"
    Team        = "platform"
    CostCenter  = "eng-0042"
  }
}
```

### Bring your own IAM role

```hcl
module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 0.3"

  name                  = "my-agent"
  create_execution_role = false
  execution_role_arn    = aws_iam_role.my_agent_role.arn
}
```

---

## 🔒 Security notes

- 🔒 **`BedrockAgentCoreFullAccess` is broad** — it is enabled by default for convenience. Set `attach_bedrock_fullaccess_policy = false` in production and grant only the actions your agent requires via `additional_iam_statements`.
- 🔒 **Prefer least privilege** — scope `bedrock:InvokeModel` to specific model ARNs and `ecr:BatchGetImage` to specific repository ARNs rather than using `"Resource": "*"`.
- 🧾 **Secrets belong in Secrets Manager or SSM Parameter Store** — do not pass sensitive values through `environment_variables`. Fetch them at runtime from `secretsmanager:GetSecretValue` or `ssm:GetParameter` instead.
- ⚙️ **The build trigger runs `local-exec`** — when `trigger_build_on_apply = true`, Terraform / OpenTofu shells out to `scripts/build-image.sh` on the machine executing `apply`. This means the executor's AWS credentials and shell environment are used. Set `trigger_build_on_apply = false` to eliminate this surface area and drive builds from a controlled CI/CD pipeline.
- 🌐 **Gateway interceptors are Lambda-backed** — each interceptor Lambda receives request or response payloads; apply appropriate resource-based policies and consider VPC isolation for sensitive workloads.

---

## 🧾 Notes and limitations

### 🐳 Agent source code

The module expects a `Dockerfile` at the root of the source directory. CodeBuild runs `docker build .` from that directory. Set `agent_source_dir` to point at your own code:

```hcl
agent_source_dir = "${path.root}/src/my-agent"
```

The archive is re-uploaded and CodeBuild is re-triggered automatically whenever any file in the directory changes, based on the MD5 hash of the zip.

### ⚙️ Build trigger

When `trigger_build_on_apply = true` (the default), the `modules/build` submodule uses a `null_resource` to call the bundled `scripts/build-image.sh` script via `local-exec`. This requires:

- **AWS CLI v2** — must be available on the machine running `terraform apply` (or `tofu apply`).
- **bash** — the build script requires a bash-compatible shell (Linux, macOS, WSL on Windows).

Set `trigger_build_on_apply = false` to remove this dependency and drive builds from your CI/CD pipeline instead.

### 🧰 ARM vs. x86

The default CodeBuild image (`amazonlinux2-aarch64-standard:3.0`) and environment type (`ARM_CONTAINER`) produce ARM64 images. To build x86 images instead, override both variables:

```hcl
codebuild_environment_image = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
codebuild_environment_type  = "LINUX_CONTAINER"
codebuild_compute_type      = "BUILD_GENERAL1_LARGE"
```

### 🔒 IAM and `BedrockAgentCoreFullAccess`

The `BedrockAgentCoreFullAccess` managed policy is attached by default. It is broad and suited for development and prototyping. For production, set `attach_bedrock_fullaccess_policy = false` and supply exactly the permissions your agent needs via `additional_iam_statements`.

The inline policy baseline grants:

- ECR image pull (scoped to the module-created repository when `create_build_pipeline = true`)
- CloudWatch Logs writes (scoped to `/aws/bedrock-agentcore/runtimes/*`)
- X-Ray tracing
- CloudWatch Metrics (scoped to the `bedrock-agentcore` namespace)
- `bedrock:InvokeModel` and `bedrock:InvokeModelWithResponseStream` against `*` — narrow this via `additional_iam_statements` if needed
- AgentCore workload access tokens

### 📦 Provider version

The AgentCore resource types (`aws_bedrockagentcore_agent_runtime`, `aws_bedrockagentcore_memory`, `aws_bedrockagentcore_gateway`) were introduced in hashicorp/aws **v6.x**. The minimum tested version is **6.21**. AgentCore is a recently launched service; provider attributes may change in minor releases. Review the [AWS provider changelog](https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md) before upgrading.

### 🧩 Using submodules independently

Each module under `modules/` is a self-contained Terraform module and can be called directly without going through the root wrapper:

```hcl
module "my_memory" {
  source = "LuisOsuna117/agentcore/aws//modules/memory"

  name                  = "my-agent-memory"
  event_expiry_duration = 60
}
```

### No official AWS affiliation

This is a community module authored and maintained by [LuisOsuna117](https://github.com/LuisOsuna117). It is not affiliated with or endorsed by AWS, HashiCorp, or the OpenTofu project.

---

## 📄 License

[Apache 2.0](LICENSE)
