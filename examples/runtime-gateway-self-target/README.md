# Runtime + Gateway + Self Runtime Target

This example provisions an AgentCore Runtime and AgentCore Gateway in one module call, then attaches the module-created runtime as an MCP Gateway Target.

```bash
tofu init
tofu apply -var="image_uri=123456789012.dkr.ecr.us-east-1.amazonaws.com/my-mcp-runtime:v1.0.0"
```

The self target uses the stable target key `runtime`. The target name also defaults to `runtime` unless `gateway_runtime_target.name` is set.
