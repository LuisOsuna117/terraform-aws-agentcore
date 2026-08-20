variable "name" {
  description = "Base name for the Browser and profiles."
  type        = string
}

variable "create_browser" {
  description = "Whether to create an AgentCore Browser. Disable for profile-only usage."
  type        = bool
  default     = true
}

variable "description" {
  description = "Description for the Browser."
  type        = string
  default     = null
}

variable "execution_role_arn" {
  description = "Optional execution role ARN for the Browser."
  type        = string
  default     = null
}

variable "network_mode" {
  description = "Browser network mode: PUBLIC or VPC."
  type        = string
  default     = "PUBLIC"

  validation {
    condition     = contains(["PUBLIC", "VPC"], var.network_mode)
    error_message = "network_mode must be PUBLIC or VPC."
  }
}

variable "vpc_security_group_ids" {
  description = "Security groups used when network_mode is VPC."
  type        = set(string)
  default     = []
}

variable "vpc_subnet_ids" {
  description = "Subnets used when network_mode is VPC."
  type        = set(string)
  default     = []
}

variable "browser_signing_enabled" {
  description = "Whether Browser request signing is enabled."
  type        = bool
  default     = false
}

variable "recording" {
  description = "Optional S3 recording configuration."
  type = object({
    enabled = optional(bool, true)
    bucket  = string
    prefix  = string
  })
  default = null
}

variable "certificate_secret_arn" {
  description = "Optional Secrets Manager ARN containing a Browser certificate."
  type        = string
  default     = null
}

variable "enterprise_policy" {
  description = "Optional Browser enterprise policy stored in S3."
  type = object({
    type       = optional(string)
    bucket     = string
    prefix     = string
    version_id = optional(string)
  })
  default = null
}

variable "profiles" {
  description = "Browser Profiles keyed by a stable caller-defined name."
  type = map(object({
    name        = optional(string)
    description = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to Browser resources."
  type        = map(string)
  default     = {}
}
