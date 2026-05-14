# AgentCore Gateway Only

This example provisions a standalone AgentCore MCP Gateway with AWS IAM inbound auth and no targets.

```bash
tofu init
tofu apply
```

Use this when a central gateway should exist before individual MCP targets are attached.
