variable "name" {
  description = "Name prefix for the example resources."
  type        = string
  default     = "agentcore-basic"
}

variable "region" {
  description = "AWS Region in which to create the resources."
  type        = string
  default     = "us-east-1"
}

variable "runtime_role_arn" {
  description = "IAM role ARN assumed by AgentCore Runtime."
  type        = string
}

variable "image_uri" {
  description = "Immutable ARM64 container image URI, preferably pinned by digest."
  type        = string
}
