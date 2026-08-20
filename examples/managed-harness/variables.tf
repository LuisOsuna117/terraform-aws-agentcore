variable "aws_region" {
  description = "AWS Region in which to create the Harness."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Managed Harness name."
  type        = string
  default     = "research-harness"
}

variable "execution_role_arn" {
  description = "IAM role assumed by the Managed Harness."
  type        = string
}

variable "model_id" {
  description = "Amazon Bedrock model ID."
  type        = string
}

variable "system_prompt" {
  description = "Managed Harness system prompt."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to the Managed Harness."
  type        = map(string)
  default     = {}
}
