# Example: CodeBuild Workflow — Trigger Disabled

Creates the full CodeBuild build pipeline (ECR + S3 + CodeBuild project) but does **not** start a build automatically on `terraform apply`.

## Use this when

- You manage builds from a separate CI/CD pipeline (GitHub Actions, GitLab CI, etc.).
- The Terraform executor (e.g. Terraform Cloud) doesn't have AWS CLI or Docker access.
- You want to decouple infra changes from image rebuilds.

## What this example creates

| Resource | Description |
|---|---|
| `aws_bedrockagentcore_agent_runtime` | The AgentCore runtime |
| `aws_ecr_repository` | Container registry for your agent image |
| `aws_s3_bucket` | Source archive bucket consumed by CodeBuild |
| `aws_codebuild_project` | Build project (not automatically triggered) |
| `aws_iam_role` × 2 | Execution role + CodeBuild service role |

## What this example does NOT do

- **Does NOT trigger a build on apply.** The runtime is created before any image exists; the first invocation will fail until you push an image.

## Triggering a build

After `tofu apply`, start a build manually:

```bash
# Using the AWS CLI
aws codebuild start-build --project-name $(tofu output -raw codebuild_project_name)

# Or using the bundled script
scripts/build-image.sh \
  $(tofu output -raw codebuild_project_name) \
  us-east-1 \
  $(tofu output -raw ecr_repository_url | cut -d/ -f2) \
  latest \
  $(tofu output -raw ecr_repository_url)
```

## Switching back to automatic triggers

Set `trigger_build_on_apply = true` (the default) to re-enable automatic builds.
