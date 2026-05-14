# Gateway with AgentCore Runtime MCP Target

This example provisions a standalone AgentCore MCP Gateway and attaches one target backed by an AgentCore Runtime that hosts an MCP server.

```bash
tofu init
tofu apply -var="agent_runtime_arn=arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/MyRuntime-a1b2c3d4e5"
```

For `agent_runtime_arn` targets, the module derives the Runtime invoke endpoint, configures outbound SigV4 auth as `bedrock-agentcore` in the current AWS region, and grants the gateway role `bedrock-agentcore:InvokeAgentRuntime` on that runtime ARN.
