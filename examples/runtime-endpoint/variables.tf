variable "aws_region" {
  description = "AWS Region in which to create the endpoint."
  type        = string
  default     = "us-east-1"
}

variable "agent_runtime_id" {
  description = "Existing AgentCore Runtime ID."
  type        = string
}

variable "agent_runtime_version" {
  description = "Optional Runtime version."
  type        = string
  default     = null
}

variable "endpoint_name" {
  description = "Runtime Endpoint name."
  type        = string
  default     = "stable"
}

variable "tags" {
  description = "Tags to apply to the Runtime Endpoint."
  type        = map(string)
  default     = {}
}
