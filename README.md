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

## Requirements

| Requirement | Version |
|---|---|
| [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/) | `>= 1.8` |
| [hashicorp/aws](https://registry.terraform.io/providers/hashicorp/aws/latest) | `>= 6.21` |
| [hashicorp/archive](https://registry.terraform.io/providers/hashicorp/archive/latest) | `>= 2.0` |
| [hashicorp/null](https://registry.terraform.io/providers/hashicorp/null/latest) | `>= 3.0` |

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

## Inputs

### Core

| Name | Description | Type | Default | Required |
|---|---|---|---|:---:|
| `name` | Base name prefix for all resources. Must start with a letter; max 32 characters; letters, numbers, and hyphens only. | `string` | — | **yes** |
| `runtime_name` | Override for the AgentCore runtime resource name. Hyphens are converted to underscores. Defaults to `name`. | `string` | `null` | no |
| `description` | Description attached to the AgentCore runtime resource. | `string` | `"Managed by terraform-aws-agentcore."` | no |
| `tags` | Tags merged onto all taggable resources alongside module-level defaults. | `map(string)` | `{}` | no |

### Runtime

| Name | Description | Type | Default | Required |
|---|---|---|---|:---:|
| `network_mode` | Network mode: `PUBLIC` or `PRIVATE`. | `string` | `"PUBLIC"` | no |
| `image_tag` | Docker image tag deployed to the runtime. Changing this triggers a new CodeBuild run. | `string` | `"latest"` | no |
| `environment_variables` | Extra environment variables injected into the runtime. `AWS_REGION` and `AWS_DEFAULT_REGION` are always set. | `map(string)` | `{}` | no |

### IAM

| Name | Description | Type | Default | Required |
|---|---|---|---|:---:|
| `create_execution_role` | Create an execution IAM role for the runtime. Set `false` to supply an existing role via `execution_role_arn`. | `bool` | `true` | no |
| `execution_role_arn` | ARN of an existing execution role. Required when `create_execution_role = false`. | `string` | `null` | no |
| `attach_bedrock_fullaccess_policy` | Attach the `BedrockAgentCoreFullAccess` AWS-managed policy to the execution role. Set `false` for a tighter posture. | `bool` | `true` | no |
| `additional_iam_statements` | Extra IAM policy statements appended to the execution role's inline policy. | `list(any)` | `[]` | no |

### ECR

| Name | Description | Type | Default | Required |
|---|---|---|---|:---:|
| `ecr_repository_name` | ECR repository name. Defaults to `name`. | `string` | `null` | no |
| `ecr_image_tag_mutability` | Tag mutability: `MUTABLE` or `IMMUTABLE`. Prefer `IMMUTABLE` in production. | `string` | `"MUTABLE"` | no |
| `ecr_scan_on_push` | Enable automatic vulnerability scanning on image push. | `bool` | `true` | no |
| `ecr_lifecycle_keep_count` | Number of most-recent images to retain; older images are expired. | `number` | `10` | no |
| `ecr_force_delete` | Delete the repository even if it contains images. Useful for non-production teardown. | `bool` | `false` | no |

### S3 / Source

| Name | Description | Type | Default | Required |
|---|---|---|---|:---:|
| `agent_source_dir` | Path to the agent application code directory. Must contain a `Dockerfile`. Defaults to `<module>/agent-code`. | `string` | `null` | no |
| `source_bucket_force_destroy` | Destroy the source S3 bucket even when it still contains objects. | `bool` | `false` | no |

### CodeBuild

| Name | Description | Type | Default | Required |
|---|---|---|---|:---:|
| `codebuild_compute_type` | CodeBuild [compute type](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html). | `string` | `"BUILD_GENERAL1_LARGE"` | no |
| `codebuild_environment_image` | Docker image for the CodeBuild build environment. | `string` | `"aws/codebuild/amazonlinux2-aarch64-standard:3.0"` | no |
| `codebuild_environment_type` | CodeBuild environment type. Must match the architecture of `codebuild_environment_image`. | `string` | `"ARM_CONTAINER"` | no |
| `codebuild_build_timeout` | Maximum build duration in minutes. Valid range: 5–480. | `number` | `60` | no |

---

## Outputs

### Runtime

| Name | Description |
|---|---|
| `agent_runtime_id` | ID of the AgentCore runtime resource. |
| `agent_runtime_arn` | ARN of the runtime. Use this to grant invoke permissions to callers. |
| `agent_runtime_name` | Resolved runtime name as registered with the AgentCore API. |
| `agent_runtime_version` | Version identifier of the deployed runtime. |
| `agent_runtime_network_mode` | Network mode of the runtime (`PUBLIC` or `PRIVATE`). |

### IAM

| Name | Description |
|---|---|
| `execution_role_arn` | ARN of the execution role (module-created or caller-supplied). |
| `execution_role_name` | Name of the module-created execution role. Empty string when `create_execution_role = false`. |
| `codebuild_role_arn` | ARN of the CodeBuild service role. |

### ECR

| Name | Description |
|---|---|
| `ecr_repository_url` | Full ECR repository URL (without tag). Base URL for `docker push`/`pull`. |
| `ecr_repository_arn` | ARN of the ECR repository. |
| `ecr_repository_name` | Name of the ECR repository. |
| `container_image_uri` | Full image URI (`repository_url:image_tag`) deployed to the runtime. |

### CodeBuild

| Name | Description |
|---|---|
| `codebuild_project_name` | Name of the CodeBuild build project. |
| `codebuild_project_arn` | ARN of the CodeBuild build project. |

### S3

| Name | Description |
|---|---|
| `source_bucket_name` | Name of the S3 source bucket. |
| `source_bucket_arn` | ARN of the S3 source bucket. |
| `source_object_key` | S3 key of the currently active source archive. |
| `source_code_md5` | MD5 of the source archive. Changes automatically trigger a CodeBuild rebuild. |

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

[MIT](LICENSE)
