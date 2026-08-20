variable "aws_region" {
  description = "AWS Region in which to create resources."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for Browser resources."
  type        = string
  default     = "browser-example"
}

variable "tags" {
  description = "Tags to apply to Browser resources."
  type        = map(string)
  default     = {}
}
