variable "aws_region" {
  description = "AWS Region containing the Memory."
  type        = string
  default     = "us-east-1"
}

variable "memory_id" {
  description = "Existing AgentCore Memory ID."
  type        = string
}
