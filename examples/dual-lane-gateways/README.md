# Dual-lane Gateways

Creates separate JWT and IAM Gateways and Runtimes, two Runtime targets, and a
fail-closed Policy Engine. It does not enable Identity, Memory, Browser, Code
Interpreter, Harness, Evaluations, Registry Preview, or observability.

The Policy Engine starts with no permit policies. Add explicit Cedar policies
before invoking either Gateway.

When copying this example, replace `source = "../.."` with the registry source
and pin the module version.
