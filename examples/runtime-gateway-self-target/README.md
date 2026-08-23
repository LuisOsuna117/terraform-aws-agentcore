# Runtime + Gateway + Self Runtime Target

This example provisions an AgentCore Runtime and AgentCore Gateway in one
module call, attaches the module-created runtime as an MCP Gateway Target, and
keeps the Gateway and Runtime resource policies in the same Terraform state.

```bash
tofu init
tofu apply \
  -var="image_uri=123456789012.dkr.ecr.us-east-1.amazonaws.com/my-mcp-runtime:v1.0.0" \
  -var='gateway_caller_role_arns=["arn:aws:iam::111122223333:role/caller"]'
```

The self target uses the stable target key `runtime`. The target name also defaults to `runtime` unless `gateway_runtime_target.name` is set.

The Gateway policy allows only `gateway_caller_role_arns`. Its default empty
set creates an explicit deny-all policy. The Runtime policy allows the Gateway
role created by this module call and explicitly denies direct invocation by
other principals.
