variable "aws_region" {
  description = "AWS Region in which to create resources."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name for the AgentCore policy engine."
  type        = string
  default     = "policy-example"
}

variable "cedar_statement" {
  description = "Cedar statement owned by the caller."
  type        = string
  default     = "forbid(principal, action, resource);"
}

variable "tags" {
  description = "Tags to apply to the policy engine."
  type        = map(string)
  default     = {}
}
