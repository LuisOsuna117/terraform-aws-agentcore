variable "name" {
  description = "CloudFormation stack name."
  type        = string
}

variable "template_body" {
  description = "CloudFormation template body for the isolated preview resource."
  type        = string
}

variable "parameters" {
  description = "CloudFormation stack parameters."
  type        = map(string)
  default     = {}
}

variable "capabilities" {
  description = "CloudFormation capabilities required by the template."
  type        = set(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the CloudFormation stack."
  type        = map(string)
  default     = {}
}
