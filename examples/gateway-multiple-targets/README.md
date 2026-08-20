# Gateway with Multiple MCP Targets

This example provisions a standalone AgentCore MCP Gateway with both an AgentCore Runtime MCP target and an explicit HTTPS MCP server target.

```bash
tofu init
tofu apply -var="agent_runtime_arn=arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/MyRuntime-a1b2c3d4e5"
```

Only AgentCore Runtime targets receive the generated `bedrock-agentcore:InvokeAgentRuntime` gateway role policy. Explicit endpoint targets are configured without that IAM invoke policy.
