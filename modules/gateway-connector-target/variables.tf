variable "gateway_identifier" {
  description = "ID of the AgentCore Gateway that owns this connector target."
  type        = string

  validation {
    condition     = can(regex("^([0-9a-z][-]?){1,100}-[0-9a-z]{10}$", var.gateway_identifier))
    error_message = "gateway_identifier must be a valid AgentCore Gateway ID."
  }
}

variable "name" {
  description = "Gateway connector target name."
  type        = string

  validation {
    condition     = can(regex("^([0-9a-zA-Z][-]?){1,100}$", var.name))
    error_message = "name must contain only letters, numbers, and hyphens, start with a letter or number, and be at most 100 characters."
  }
}

variable "description" {
  description = "Optional Gateway connector target description."
  type        = string
  default     = null

  validation {
    condition     = var.description == null ? true : length(var.description) >= 1 && length(var.description) <= 200
    error_message = "description must contain between 1 and 200 characters when set."
  }
}

variable "connector_id" {
  description = "AgentCore built-in connector identifier, for example web-search."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-z][0-9a-z-]{0,99}$", var.connector_id))
    error_message = "connector_id must contain lowercase letters, numbers, or hyphens."
  }
}

variable "connector_version" {
  description = "Pinned connector version. A version is required so provider defaults cannot change behavior silently."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.connector_version))
    error_message = "connector_version must be an explicit semantic version such as 1.2.0."
  }
}

variable "configurations" {
  description = "Connector tool configurations passed to AgentCore."
  type = list(object({
    name             = string
    parameter_values = optional(any, {})
  }))

  validation {
    condition = length(var.configurations) > 0 && alltrue([
      for configuration in var.configurations : trimspace(configuration.name) != ""
    ])
    error_message = "configurations must contain at least one named connector tool configuration."
  }
}

variable "region" {
  description = "AWS Region in which to manage the connector target. Defaults to the provider Region."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the CloudFormation stack and its taggable resources."
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Optional create, update, and delete timeouts for the CloudFormation stack."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
