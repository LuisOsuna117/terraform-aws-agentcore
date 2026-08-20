# Basic Runtime

Creates one IAM-authenticated AgentCore Runtime from a caller-owned execution
role and an immutable ARM64 container image.

```bash
tofu init
tofu plan \
  -var='runtime_role_arn=arn:aws:iam::111122223333:role/example-runtime' \
  -var='image_uri=111122223333.dkr.ecr.us-east-1.amazonaws.com/example@sha256:...'
```

When copying this example, replace `source = "../.."` with the registry source
and pin the module version.
