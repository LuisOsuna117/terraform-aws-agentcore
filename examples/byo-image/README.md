# Example: Bring Your Own Image (BYO)

Deploys an AgentCore runtime using a container image **you supply**. No CodeBuild project, S3 bucket, or ECR repository is created.

## Use this when

- You already have a CI/CD pipeline (GitHub Actions, GitLab CI, etc.) that builds and pushes your agent image.
- You want the simplest possible Terraform footprint — runtime + IAM role only.

## What this example creates

| Resource | Description |
|---|---|
| `aws_bedrockagentcore_agent_runtime` | The AgentCore runtime pointed at your image |
| `aws_iam_role` | Execution role (unless `create_execution_role = false`) |

## What this example does NOT create

- ECR repository
- S3 source bucket
- CodeBuild project
- Build trigger

## Usage

```hcl
module "agentcore" {
  source = "LuisOsuna117/agentcore/aws"
  version = "~> 1.0"

  name                  = "my-agent"
  create_build_pipeline = false
  create_runtime        = true
  create_execution_role = true
  image_uri             = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-agent:v1.2.3"
}
```

```bash
tofu init
tofu apply -var="image_uri=123456789012.dkr.ecr.us-east-1.amazonaws.com/my-agent:latest"
```

## Private ECR images

AgentCore Runtime accepts images from Amazon ECR. Grant the execution role
permission to pull the selected repository:

```hcl
additional_iam_statements = [
  {
    Sid    = "ECRImagePull"
    Effect = "Allow"
    Action = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
    ]
    Resource = "arn:aws:ecr:us-east-1:123456789012:repository/my-agent"
  },
]
```
