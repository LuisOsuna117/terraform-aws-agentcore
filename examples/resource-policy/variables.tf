variable "aws_region" {
  description = "AWS Region in which to manage the resource policy."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Stable name for this module invocation."
  type        = string
  default     = "resource-policy-example"
}

variable "gateway_arn" {
  description = "ARN of the AgentCore Gateway protected by the resource policy."
  type        = string
}

variable "trusted_principal_arns" {
  description = "IAM principal ARNs allowed to invoke the Gateway."
  type        = list(string)
}
