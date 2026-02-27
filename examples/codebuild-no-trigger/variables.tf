variable "aws_region" {
  description = "AWS region to deploy the example into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for the AgentCore resources created by this example."
  type        = string
  default     = "no-trigger-agent"
}
