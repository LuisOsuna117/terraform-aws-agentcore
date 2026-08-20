variable "name" {
  description = "Name prefix for the example resources."
  type        = string
  default     = "agentcore-image-build"
}

variable "region" {
  description = "AWS Region in which to create the resources."
  type        = string
  default     = "us-east-1"
}

variable "trigger_build_on_apply" {
  description = "Start and wait for CodeBuild during apply."
  type        = bool
  default     = false
}
