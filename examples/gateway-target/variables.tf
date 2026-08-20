variable "aws_region" {
  description = "AWS Region containing the Gateway."
  type        = string
  default     = "us-east-1"
}

variable "gateway_identifier" {
  description = "Existing AgentCore Gateway ID."
  type        = string
}

variable "runtime_arn" {
  description = "Existing AgentCore Runtime ARN."
  type        = string
}
