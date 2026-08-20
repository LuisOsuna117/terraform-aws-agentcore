# Complete governed topology

Creates separate JWT and IAM Gateways and Runtimes, a fail-closed Policy Engine,
AgentCore Identity, Memory, Browser, Browser Profile, Code Interpreter, and a
365-day observability log group.

The Policy Engine starts with no permit policies. Add explicit Cedar policies
before invoking either Gateway.

When copying this example, replace `source = "../.."` with the registry source
and pin the module version.
