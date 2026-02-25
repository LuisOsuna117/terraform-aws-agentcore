# terraform-aws-agentcore

> **Community module** — not affiliated with or endorsed by AWS.
> Published on the [Terraform Registry](https://registry.terraform.io/modules/LuisOsuna117/agentcore/aws) and the [OpenTofu Registry](https://search.opentofu.org/module/LuisOsuna117/agentcore/aws). Compatible with both **Terraform ≥ 1.8** and **OpenTofu ≥ 1.8**.

A Terraform / OpenTofu module that provisions an [Amazon Bedrock AgentCore](https://docs.aws.amazon.com/bedrock/latest/userguide/agentcore.html) runtime on AWS, together with the supporting infrastructure needed to build and deploy containerised agents.

**Easy to start, extensible for production.** One required variable (`name`) gets a working runtime. A set of clearly named optional inputs let you harden it for real workloads — without forking the module or fighting the abstractions.

---

## Features

- **Single required variable** — only `name` is mandatory; every other input has a safe default.
- **Execution role escape hatch** — bring your own IAM role or let the module create one.
- **Extensible IAM** — append policy statements to the execution role via `additional_iam_statements` without touching the module source.
- **Content-addressed source uploads** — S3 object keys include the archive MD5, so CodeBuild is only re-triggered when agent code actually changes.
- **Configurable ECR** — tag mutability, scan-on-push, lifecycle retention, and force-delete are all tunable.
- **Consistent tagging** — a `tags` map is merged onto every taggable resource alongside module-managed defaults.
- **Validated inputs** — naming patterns, enum values, and numeric bounds are enforced by `validation` blocks before any plan is generated.

---

## What this module creates

| Resource | Purpose |
|---|---|
| `aws_bedrockagentcore_agent_runtime` | The AgentCore runtime that executes your agent container. |
| `aws_ecr_repository` | Private container registry for agent images. |
| `aws_ecr_repository_policy` | Allows principals in the same account to pull images. |
| `aws_ecr_lifecycle_policy` | Retains the N most-recent images and expires the rest. |
| `aws_iam_role` (execution) | Runtime execution role assumed by the AgentCore service. |
| `aws_iam_role_policy` (execution) | Least-privilege inline policy: ECR pull, CloudWatch Logs, X-Ray, CloudWatch Metrics, Bedrock invocation, workload access tokens. |
| `aws_iam_role_policy_attachment` | Optional attachment of the `BedrockAgentCoreFullAccess` managed policy. |
| `aws_iam_role` (codebuild) | Service role for the CodeBuild image-build pipeline. |
| `aws_iam_role_policy` (codebuild) | Inline policy: CloudWatch Logs, ECR push, S3 source read. |
| `aws_codebuild_project` | Builds the agent Docker image and pushes it to ECR. |
| `aws_s3_bucket` | Private versioned bucket for agent source code. |
| `aws_s3_bucket_public_access_block` | Blocks all public access to the source bucket. |
| `aws_s3_bucket_versioning` | Enables versioning on the source bucket. |
| `aws_s3_object` | Content-addressed archive of your agent source directory. |

## What this module does NOT create

- **VPC, subnets, or security groups** — required when using `network_mode = "PRIVATE"`, but out of scope for this module.
- **Bedrock model access** — enable foundation model access separately in the AWS console.
- **AgentCore gateway or memory resources** — planned as separate companion modules.
- **KMS encryption** — S3 and ECR use AWS-managed encryption by default. Manage customer-managed keys outside this module.

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.21 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.21 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_bedrockagentcore_agent_runtime.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_agent_runtime) | resource |
| [aws_codebuild_project.agent_image](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_iam_role.agent_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.image_build](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.agent_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.image_build](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.agent_execution_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.agent_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.agent_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.agent_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.agent_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.agent_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [null_resource.trigger_build](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [archive_file.agent_source](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
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
| <a name="input_create_execution_role"></a> [create\_execution\_role](#input\_create\_execution\_role) | When true, the module creates an IAM execution role for the AgentCore runtime. Set to false to provide an existing role via execution\_role\_arn. | `bool` | `true` | no |
| <a name="input_description"></a> [description](#input\_description) | Human-readable description attached to the AgentCore runtime resource. | `string` | `"Managed by terraform-aws-agentcore."` | no |
| <a name="input_ecr_force_delete"></a> [ecr\_force\_delete](#input\_ecr\_force\_delete) | Allow the ECR repository to be deleted even if it contains images. Useful in non-production environments. Defaults to false for safety. | `bool` | `false` | no |
| <a name="input_ecr_image_tag_mutability"></a> [ecr\_image\_tag\_mutability](#input\_ecr\_image\_tag\_mutability) | Tag mutability setting for the ECR repository. IMMUTABLE is recommended for production to prevent image overwrites. | `string` | `"MUTABLE"` | no |
| <a name="input_ecr_lifecycle_keep_count"></a> [ecr\_lifecycle\_keep\_count](#input\_ecr\_lifecycle\_keep\_count) | Number of most-recent images to retain in the ECR repository. Older images are expired automatically. | `number` | `10` | no |
| <a name="input_ecr_repository_name"></a> [ecr\_repository\_name](#input\_ecr\_repository\_name) | Name of the ECR repository that holds agent container images. Defaults to var.name when null. | `string` | `null` | no |
| <a name="input_ecr_scan_on_push"></a> [ecr\_scan\_on\_push](#input\_ecr\_scan\_on\_push) | Enable automatic vulnerability scanning when an image is pushed to the ECR repository. | `bool` | `true` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Additional environment variables injected into the AgentCore runtime process. AWS\_REGION and AWS\_DEFAULT\_REGION are always set automatically. | `map(string)` | `{}` | no |
| <a name="input_execution_role_arn"></a> [execution\_role\_arn](#input\_execution\_role\_arn) | ARN of an existing IAM role to use as the AgentCore runtime execution role. Required when create\_execution\_role = false. | `string` | `null` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Docker image tag to deploy to the AgentCore runtime. Changing this triggers a new CodeBuild run. | `string` | `"latest"` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name used as a prefix for all resources created by this module (e.g. "my-agent"). Must start with a letter, max 32 characters. | `string` | n/a | yes |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | Network mode for the AgentCore runtime. PUBLIC exposes the runtime endpoint on the public internet; PRIVATE keeps it internal to your VPC. | `string` | `"PUBLIC"` | no |
| <a name="input_runtime_name"></a> [runtime\_name](#input\_runtime\_name) | Override for the AgentCore runtime resource name. Defaults to var.name when null. Hyphens are automatically converted to underscores to satisfy the AgentCore API. | `string` | `null` | no |
| <a name="input_source_bucket_force_destroy"></a> [source\_bucket\_force\_destroy](#input\_source\_bucket\_force\_destroy) | Allow the S3 source bucket to be destroyed even if it contains objects. Useful in non-production environments. Defaults to false for safety. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all taggable resources. Merged with module-level defaults. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agent_runtime_arn"></a> [agent\_runtime\_arn](#output\_agent\_runtime\_arn) | ARN of the AgentCore runtime. Use this to grant invoke permissions to callers. |
| <a name="output_agent_runtime_id"></a> [agent\_runtime\_id](#output\_agent\_runtime\_id) | ID of the AgentCore runtime resource. |
| <a name="output_agent_runtime_name"></a> [agent\_runtime\_name](#output\_agent\_runtime\_name) | Resolved name of the AgentCore runtime as registered with the Bedrock AgentCore API. |
| <a name="output_agent_runtime_network_mode"></a> [agent\_runtime\_network\_mode](#output\_agent\_runtime\_network\_mode) | Network mode of the runtime (PUBLIC or PRIVATE). |
| <a name="output_agent_runtime_version"></a> [agent\_runtime\_version](#output\_agent\_runtime\_version) | Version identifier of the deployed AgentCore runtime. |
| <a name="output_codebuild_project_arn"></a> [codebuild\_project\_arn](#output\_codebuild\_project\_arn) | ARN of the CodeBuild project. |
| <a name="output_codebuild_project_name"></a> [codebuild\_project\_name](#output\_codebuild\_project\_name) | Name of the CodeBuild project used to build and push the agent image. |
| <a name="output_codebuild_role_arn"></a> [codebuild\_role\_arn](#output\_codebuild\_role\_arn) | ARN of the IAM role used by the CodeBuild image-build project. |
| <a name="output_container_image_uri"></a> [container\_image\_uri](#output\_container\_image\_uri) | Full container image URI (repository URL + tag) deployed to the runtime. |
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | ARN of the ECR repository. |
| <a name="output_ecr_repository_name"></a> [ecr\_repository\_name](#output\_ecr\_repository\_name) | Name of the ECR repository as registered in the AWS account. |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | Full ECR repository URL (without tag). Use as the base for docker push/pull commands. |
| <a name="output_execution_role_arn"></a> [execution\_role\_arn](#output\_execution\_role\_arn) | ARN of the IAM role used by the AgentCore runtime. Will equal var.execution\_role\_arn when create\_execution\_role = false. |
| <a name="output_execution_role_name"></a> [execution\_role\_name](#output\_execution\_role\_name) | Name of the module-created execution role. Empty string when create\_execution\_role = false. |
| <a name="output_source_bucket_arn"></a> [source\_bucket\_arn](#output\_source\_bucket\_arn) | ARN of the S3 source bucket. |
| <a name="output_source_bucket_name"></a> [source\_bucket\_name](#output\_source\_bucket\_name) | Name of the S3 bucket holding the agent source code archive. |
| <a name="output_source_code_md5"></a> [source\_code\_md5](#output\_source\_code\_md5) | MD5 hash of the agent source code archive. Changes when source files change and triggers a new CodeBuild run. |
| <a name="output_source_object_key"></a> [source\_object\_key](#output\_source\_object\_key) | S3 object key for the currently uploaded agent source code archive. |
<!-- END_TF_DOCS -->

---

**Local runtime dependencies** (on the machine running `terraform apply` / `tofu apply`):

- AWS CLI v2 — used by the `local-exec` build trigger to start and poll a CodeBuild run.
- `bash` — the build script requires a bash-compatible shell (Linux, macOS, WSL on Windows).

---

## Examples

| Example | Description |
|---|---|
| [examples/basic](examples/basic) | Minimal runtime — one module call with sensible defaults and a working Python agent stub. |

---

## Usage

### Minimal

```hcl
provider "aws" {
  region = "us-east-1"
}

module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 1.0"

  name = "my-agent"
}
```

Place your agent application code (including a `Dockerfile`) in `./agent-code/` relative to the module source, then run `terraform apply` or `tofu apply`. The module zips the directory, uploads it to S3, triggers a CodeBuild build, and provisions the runtime.

### Custom source directory and pinned image tag

```hcl
module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 1.0"

  name             = "my-agent"
  agent_source_dir = "${path.root}/src/my-agent"
  image_tag        = "1.2.0"
}
```

### Production configuration

```hcl
module "agentcore" {
  source  = "LuisOsuna117/agentcore/aws"
  version = "~> 1.0"

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
  version = "~> 1.0"

  name                  = "my-agent"
  create_execution_role = false
  execution_role_arn    = aws_iam_role.my_agent_role.arn
}
```

---

## Notes and limitations

### Agent source code

The module expects a `Dockerfile` at the root of the source directory. CodeBuild runs `docker build .` from that directory. Set `agent_source_dir` to point at your own code:

```hcl
agent_source_dir = "${path.root}/src/my-agent"
```

The archive is re-uploaded and CodeBuild is re-triggered automatically whenever any file in the directory changes, based on the MD5 hash of the zip.

### Build trigger

The `local-exec` provisioner runs the AWS CLI on the machine executing `terraform apply` / `tofu apply`. This works well for local development and simple CI pipelines that have AWS credentials available. For more controlled production pipelines, manage CodeBuild execution outside of Terraform / OpenTofu using the `codebuild_project_name` output.

### ARM vs. x86

The default CodeBuild image (`amazonlinux2-aarch64-standard:3.0`) and environment type (`ARM_CONTAINER`) produce ARM64 images. To build x86 images instead, override both variables:

```hcl
codebuild_environment_image = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
codebuild_environment_type  = "LINUX_CONTAINER"
codebuild_compute_type      = "BUILD_GENERAL1_LARGE"
```

### IAM and `BedrockAgentCoreFullAccess`

The `BedrockAgentCoreFullAccess` managed policy is attached by default. It is broad and suited for development and prototyping. For production, set `attach_bedrock_fullaccess_policy = false` and supply exactly the permissions your agent needs via `additional_iam_statements`.

The inline policy baseline grants:

- ECR image pull (scoped to the module-created repository)
- CloudWatch Logs writes (scoped to `/aws/bedrock-agentcore/runtimes/*`)
- X-Ray tracing
- CloudWatch Metrics (scoped to the `bedrock-agentcore` namespace)
- `bedrock:InvokeModel` and `bedrock:InvokeModelWithResponseStream` against `*` — narrow this via `additional_iam_statements` if needed
- AgentCore workload access tokens

### Provider version

`aws_bedrockagentcore_agent_runtime` was introduced in hashicorp/aws **v6.x**. The minimum tested version is **6.21**. AgentCore is a recently launched service; provider attributes may change in minor releases. Review the [AWS provider changelog](https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md) before upgrading.

### No official AWS affiliation

This is a community module authored and maintained by [LuisOsuna117](https://github.com/LuisOsuna117). It is not affiliated with or endorsed by AWS, HashiCorp, or the OpenTofu project.

---

## License

[Apache 2.0](LICENSE)
