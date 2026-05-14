variable "aws_region" {
  description = "AWS region to deploy the example into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for the AgentCore Gateway resources created by this example."
  type        = string
  default     = "runtime-mcp-gateway"
}

variable "agent_runtime_arn" {
  description = "ARN of the AgentCore Runtime that hosts an MCP server."
  type        = string
}

variable "qualifier" {
  description = "AgentCore Runtime qualifier to invoke through the gateway target."
  type        = string
  default     = "DEFAULT"
}
