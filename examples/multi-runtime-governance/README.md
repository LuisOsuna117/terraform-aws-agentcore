# Multi-Runtime governance

This example uses one root module instance to create two explicitly separated
AgentCore lanes:

- an interactive Runtime and Gateway protected by JWT passthrough;
- an automation Runtime and Gateway protected by IAM;
- one shared Policy Engine in `LOG_ONLY` mode;
- opt-in Memory and Browser access only for the interactive Runtime.

The two Runtime execution roles are created independently. Model access remains
scoped to `model_arns`, and the automation Gateway is fail-closed to
`automation_caller_role_arns`.

```bash
tofu init
tofu plan \
  -var='image_uri=123456789012.dkr.ecr.us-east-1.amazonaws.com/agents@sha256:...' \
  -var='model_arns=["arn:aws:bedrock:us-east-1:123456789012:inference-profile/example"]' \
  -var='jwt_discovery_url=https://example.auth.us-east-1.amazoncognito.com/.well-known/openid-configuration' \
  -var='jwt_allowed_clients=["example-client"]' \
  -var='automation_caller_role_arns=["arn:aws:iam::123456789012:role/example-dispatcher"]'
```

Promote the Gateway policy modes to `ENFORCE` only after attaching and
validating the Cedar or Dogwood policies required by your workload.
