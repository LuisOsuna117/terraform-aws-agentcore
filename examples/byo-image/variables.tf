variable "aws_region" {
  description = "AWS region to deploy the example into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for the AgentCore resources created by this example."
  type        = string
  default     = "byo-agent"
}

variable "image_uri" {
  description = "Full container image URI to deploy (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-agent:v1.0.0)."
  type        = string
}
