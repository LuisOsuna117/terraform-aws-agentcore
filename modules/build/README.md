# AgentCore Image Build submodule

Creates an opt-in Amazon ECR repository, source archive bucket, and CodeBuild
project for an AgentCore container image. Repository access, image expiration,
and apply-time build triggers are independent opt-ins.

Use the focused examples at [`examples/basic`](../../examples/basic) and
[`examples/codebuild-no-trigger`](../../examples/codebuild-no-trigger).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.61, < 7.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.61, < 7.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_codebuild_project.agent_image](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_iam_role.image_build](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.image_build](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
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
| <a name="input_agent_source_dir"></a> [agent\_source\_dir](#input\_agent\_source\_dir) | Resolved path to the agent application directory. | `string` | n/a | yes |
| <a name="input_codebuild_build_timeout"></a> [codebuild\_build\_timeout](#input\_codebuild\_build\_timeout) | Maximum build duration in minutes. | `number` | `60` | no |
| <a name="input_codebuild_compute_type"></a> [codebuild\_compute\_type](#input\_codebuild\_compute\_type) | Compute type for the CodeBuild environment. | `string` | `"BUILD_GENERAL1_LARGE"` | no |
| <a name="input_codebuild_environment_image"></a> [codebuild\_environment\_image](#input\_codebuild\_environment\_image) | Docker image used for the CodeBuild build environment. | `string` | `"aws/codebuild/amazonlinux2-aarch64-standard:3.0"` | no |
| <a name="input_codebuild_environment_type"></a> [codebuild\_environment\_type](#input\_codebuild\_environment\_type) | CodeBuild environment type. | `string` | `"ARM_CONTAINER"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Pre-merged tag map passed from the root module. | `map(string)` | `{}` | no |
| <a name="input_ecr_force_delete"></a> [ecr\_force\_delete](#input\_ecr\_force\_delete) | Destroy the ECR repository even when it contains images. | `bool` | `false` | no |
| <a name="input_ecr_image_tag_mutability"></a> [ecr\_image\_tag\_mutability](#input\_ecr\_image\_tag\_mutability) | Tag mutability setting for the ECR repository. | `string` | `"MUTABLE"` | no |
| <a name="input_ecr_lifecycle_keep_count"></a> [ecr\_lifecycle\_keep\_count](#input\_ecr\_lifecycle\_keep\_count) | Number of most-recent images to retain. Null creates no lifecycle policy. | `number` | `null` | no |
| <a name="input_ecr_pull_principals"></a> [ecr\_pull\_principals](#input\_ecr\_pull\_principals) | IAM principal ARNs allowed to pull images through a repository policy. Empty creates no repository policy. | `list(string)` | `[]` | no |
| <a name="input_ecr_repository_name"></a> [ecr\_repository\_name](#input\_ecr\_repository\_name) | Name of the ECR repository. Passed as the resolved local from the root. | `string` | n/a | yes |
| <a name="input_ecr_scan_on_push"></a> [ecr\_scan\_on\_push](#input\_ecr\_scan\_on\_push) | Enable automatic vulnerability scanning on image push. | `bool` | `true` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Docker image tag to build and push. | `string` | `"latest"` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name prefix shared with the root module. | `string` | n/a | yes |
| <a name="input_source_bucket_force_destroy"></a> [source\_bucket\_force\_destroy](#input\_source\_bucket\_force\_destroy) | Destroy the S3 source bucket even when it contains objects. | `bool` | `false` | no |
| <a name="input_trigger_build_on_apply"></a> [trigger\_build\_on\_apply](#input\_trigger\_build\_on\_apply) | When true, automatically starts a CodeBuild run on every terraform apply where source or configuration changes. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_codebuild_project_arn"></a> [codebuild\_project\_arn](#output\_codebuild\_project\_arn) | ARN of the CodeBuild project. |
| <a name="output_codebuild_project_name"></a> [codebuild\_project\_name](#output\_codebuild\_project\_name) | Name of the CodeBuild project. |
| <a name="output_codebuild_role_arn"></a> [codebuild\_role\_arn](#output\_codebuild\_role\_arn) | ARN of the CodeBuild service role. |
| <a name="output_codebuild_start_build_command"></a> [codebuild\_start\_build\_command](#output\_codebuild\_start\_build\_command) | AWS CLI command to trigger a build manually. Useful for CI pipelines when trigger\_build\_on\_apply = false. |
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | ARN of the ECR repository. |
| <a name="output_ecr_repository_name"></a> [ecr\_repository\_name](#output\_ecr\_repository\_name) | Name of the ECR repository. |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | Full ECR repository URL (without tag). |
| <a name="output_image_uri"></a> [image\_uri](#output\_image\_uri) | Full container image URI (ecr\_repository\_url:image\_tag) that this build pipeline produces. |
| <a name="output_source_bucket_arn"></a> [source\_bucket\_arn](#output\_source\_bucket\_arn) | ARN of the S3 source bucket. |
| <a name="output_source_bucket_name"></a> [source\_bucket\_name](#output\_source\_bucket\_name) | Name of the S3 bucket holding the agent source code. |
<!-- END_TF_DOCS -->
