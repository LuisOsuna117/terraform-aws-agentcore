# Example: CodeBuild Workflow — Trigger Disabled

Creates the CodeBuild build pipeline (ECR + S3 + CodeBuild project) but does
**not** start a build or create a Runtime on the first `terraform apply`.

## Use this when

- You manage builds from a separate CI/CD pipeline (GitHub Actions, GitLab CI, etc.).
- The Terraform executor must not start builds as a side effect of apply.
- You want to decouple infra changes from image rebuilds.

## What this example creates

| Resource | Description |
|---|---|
| `aws_ecr_repository` | Container registry for your agent image |
| `aws_s3_bucket` | Source archive bucket consumed by CodeBuild |
| `aws_codebuild_project` | Build project (not automatically triggered) |
| `aws_iam_role` | CodeBuild service role |

## What this example does NOT do

- Does not trigger a build on apply.
- Does not create a Runtime before its ECR image exists.

## Triggering a build

After `tofu apply`, start a build manually:

```bash
# Using the AWS CLI
aws codebuild start-build --project-name $(tofu output -raw codebuild_project_name)

tofu output -raw codebuild_start_build_command
```

After CodeBuild pushes the image, set `create_runtime = true` and
`create_execution_role = true`, then apply again. The Runtime is now created
against an existing image.

## Enabling automatic triggers

Set `trigger_build_on_apply = true` explicitly. This requires bash and AWS CLI
v2 on the Terraform executor.
