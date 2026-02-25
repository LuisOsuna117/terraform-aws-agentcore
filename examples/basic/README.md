# Example: Basic AgentCore Runtime

This example provisions a minimal Amazon Bedrock AgentCore runtime using the
[terraform-aws-agentcore](https://github.com/LuisOsuna117/terraform-aws-agentcore)
module.

## What it creates

- An AgentCore runtime (`PUBLIC` network mode)
- An ECR repository for the agent container image
- A CodeBuild project that builds and pushes the image automatically
- An IAM execution role with least-privilege permissions
- A private S3 bucket for agent source code

## Usage

1. **Customise the agent code** in `agent-code/` — replace `agent.py` with your own logic. The directory must contain a `Dockerfile` at its root.

2. **Initialise OpenTofu / Terraform:**

   ```bash
   tofu init
   # or: terraform init
   ```

3. **Deploy:**

   ```bash
   tofu apply
   # or: terraform apply
   ```

   The apply will:
   - Create the S3 bucket and upload a zip of `agent-code/`
   - Create the ECR repository and CodeBuild project
   - Trigger a CodeBuild build that produces the container image
   - Provision the AgentCore runtime pointing at that image

4. **Verify:**

   ```bash
   tofu output agent_runtime_arn
   ```

## Requirements

| Requirement | Version |
|---|---|
| OpenTofu or Terraform | `>= 1.8` |
| hashicorp/aws provider | `>= 6.21` |
| AWS CLI v2 | latest |
| bash | any |

## Inputs

| Name | Default | Description |
|---|---|---|
| `aws_region` | `us-east-1` | AWS region to deploy into. |
| `name` | `basic-agent` | Base name for all resources. |

## Notes

- `ecr_force_delete` and `source_bucket_force_destroy` are left at their defaults (`false`) — set them to `true` if you want `tofu destroy` to clean up completely in a sandbox environment.
- The agent stub in `agent-code/agent.py` depends on the `bedrock-agentcore` Python package. Update `requirements.txt` to pin a specific version for production use.
