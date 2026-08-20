variable "aws_region" {
  description = "AWS Region containing the Gateway."
  type        = string
  default     = "us-east-1"
}

variable "gateway_identifier" {
  description = "Existing AgentCore Gateway ID."
  type        = string
}

variable "target_name" {
  description = "Existing Gateway target name."
  type        = string
}
