variable "aws_region" {
  description = "AWS region to deploy the example into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for the AgentCore runtime and gateway resources."
  type        = string
  default     = "runtime-mcp-gateway"
}

variable "image_uri" {
  description = "Full ARM64 container image URI for an MCP-capable AgentCore runtime."
  type        = string
}
