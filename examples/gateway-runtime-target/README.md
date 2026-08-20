# General Gateway with an HTTP Runtime Target

This example provisions a general AgentCore Gateway and attaches one HTTP
Runtime target. The Gateway forwards requests directly to AgentCore Runtime
without MCP aggregation or protocol translation.

```bash
tofu init
tofu apply -var="agent_runtime_arn=arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/MyRuntime-a1b2c3d4e5"
```

The target is available at the URL returned by `gateway_target_invocation_urls`, in the form `https://{gateway-id}.gateway.bedrock-agentcore.{region}.amazonaws.com/runtime/invocations`. The module configures Gateway IAM outbound authorization and grants the gateway role `bedrock-agentcore:InvokeAgentRuntime` on the runtime and qualifier endpoint ARNs.
