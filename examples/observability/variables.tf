variable "name" {
  description = "Name prefix for the example resources."
  type        = string
  default     = "agentcore-observability"
}

variable "region" {
  description = "AWS Region in which to create the resources."
  type        = string
  default     = "us-east-1"
}
