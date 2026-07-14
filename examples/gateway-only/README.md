# AgentCore Gateway Only

This example provisions a standalone general AgentCore Gateway with AWS IAM inbound auth and no targets. Set `gateway_protocol_type = "MCP"` if the empty gateway will later receive MCP aggregation targets.

```bash
tofu init
tofu apply
```

Use this when a central gateway should exist before individual targets are attached.
