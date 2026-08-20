variable "agent_runtime_id" {
  description = "AgentCore Runtime ID to qualify with this endpoint."
  type        = string
}

variable "name" {
  description = "Runtime Endpoint name."
  type        = string
}

variable "agent_runtime_version" {
  description = "Optional Runtime version routed by this endpoint."
  type        = string
  default     = null
}

variable "description" {
  description = "Runtime Endpoint description."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the Runtime Endpoint."
  type        = map(string)
  default     = {}
}
