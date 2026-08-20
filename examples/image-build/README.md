# Agent image build

Creates only the image supply chain for an AgentCore workload: an ECR
repository, versioned private S3 source bucket, least-privilege CodeBuild role,
and ARM64 CodeBuild project. It does not create a Runtime or any other
AgentCore capability.

Builds are CI-driven by default:

```bash
tofu apply
$(tofu output -raw codebuild_start_build_command)
```

Set `trigger_build_on_apply = true` to start and wait for the build during
`apply`; that mode requires Bash and AWS CLI v2 on the Terraform executor.

When copying this example, replace `source = "../.."` with the registry source
and pin the module version.
