variable "aws_region" {
  description = "AWS region to deploy the example into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for the AgentCore Gateway resources created by this example."
  type        = string
  default     = "multi-mcp-gateway"
}

variable "agent_runtime_arn" {
  description = "ARN of the AgentCore Runtime that hosts an MCP server."
  type        = string
}

variable "external_mcp_endpoint" {
  description = "HTTPS endpoint for a non-AgentCore MCP server."
  type        = string
  default     = "https://mcp.example.com/mcp"
}
