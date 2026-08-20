variable "name" {
  description = "Name of the shadow AWS Agent Registry."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_./-]{0,63}$", var.name))
    error_message = "Registry names must satisfy the AWS Agent Registry naming contract."
  }
}

variable "log_retention_days" {
  description = "Retention for the lifecycle function log group."
  type        = number
  default     = 365
}

variable "tags" {
  description = "Tags applied to Registry Preview resources."
  type        = map(string)
  default     = {}
}
