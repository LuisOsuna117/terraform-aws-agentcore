variable "gateway_identifier" {
  description = "ID of the AgentCore Gateway that owns the Runtime target."
  type        = string

  validation {
    condition     = can(regex("^([0-9a-z][-]?){1,100}-[0-9a-z]{10}$", var.gateway_identifier))
    error_message = "gateway_identifier must be a valid AgentCore Gateway ID."
  }
}

variable "name" {
  description = "Gateway Runtime target name."
  type        = string

  validation {
    condition     = can(regex("^([0-9a-zA-Z][-]?){1,100}$", var.name))
    error_message = "name must contain only letters, numbers, and hyphens, start with a letter or number, and be at most 100 characters."
  }
}

variable "description" {
  description = "Optional Gateway Runtime target description."
  type        = string
  default     = null
}

variable "runtime_arn" {
  description = "ARN of the AgentCore Runtime behind the target."
  type        = string
}

variable "qualifier" {
  description = "Runtime endpoint qualifier."
  type        = string
  default     = "DEFAULT"
}

variable "schema" {
  description = "HTTP Runtime API schema source. Set exactly one of inline_payload or s3."
  type = object({
    inline_payload = optional(object({
      payload = string
    }))
    s3 = optional(object({
      uri                     = string
      bucket_owner_account_id = optional(string)
    }))
  })
  nullable = false

  validation {
    condition = length(compact([
      var.schema.inline_payload == null ? "" : "inline_payload",
      var.schema.s3 == null ? "" : "s3",
    ])) == 1
    error_message = "schema must set exactly one of inline_payload or s3."
  }
}

variable "credential_provider_configuration" {
  description = "Optional outbound credential configuration for the Runtime target."
  type = object({
    api_key = optional(object({
      provider_arn              = string
      credential_location       = optional(string)
      credential_parameter_name = optional(string)
      credential_prefix         = optional(string)
    }))
    caller_iam_credentials = optional(object({
      service = string
      region  = optional(string)
    }))
    gateway_iam_role = optional(object({
      service = optional(string)
      region  = optional(string)
    }))
    jwt_passthrough = optional(bool, false)
    oauth = optional(object({
      provider_arn       = string
      grant_type         = optional(string)
      scopes             = set(string)
      default_return_url = optional(string)
      custom_parameters  = optional(map(string), {})
    }))
  })
  default = null

  validation {
    condition = var.credential_provider_configuration == null || length(compact([
      try(var.credential_provider_configuration.api_key, null) == null ? "" : "api_key",
      try(var.credential_provider_configuration.caller_iam_credentials, null) == null ? "" : "caller_iam_credentials",
      try(var.credential_provider_configuration.gateway_iam_role, null) == null ? "" : "gateway_iam_role",
      try(var.credential_provider_configuration.jwt_passthrough, false) ? "jwt_passthrough" : "",
      try(var.credential_provider_configuration.oauth, null) == null ? "" : "oauth",
    ])) == 1
    error_message = "credential_provider_configuration must set exactly one credential provider."
  }
}

variable "metadata_configuration" {
  description = "Optional HTTP header and query parameter propagation configuration."
  type = object({
    allowed_query_parameters = optional(set(string), [])
    allowed_request_headers  = optional(set(string), [])
    allowed_response_headers = optional(set(string), [])
  })
  default = null
}

variable "private_endpoint" {
  description = "Optional private connectivity configuration."
  type = object({
    managed_vpc_resource = optional(object({
      vpc_identifier           = string
      subnet_ids               = set(string)
      endpoint_ip_address_type = string
      security_group_ids       = optional(set(string), [])
      routing_domain           = optional(string)
      tags                     = optional(map(string), {})
    }))
    self_managed_lattice_resource = optional(object({
      resource_configuration_identifier = string
    }))
  })
  default = null

  validation {
    condition = var.private_endpoint == null || length(compact([
      try(var.private_endpoint.managed_vpc_resource, null) == null ? "" : "managed_vpc_resource",
      try(var.private_endpoint.self_managed_lattice_resource, null) == null ? "" : "self_managed_lattice_resource",
    ])) == 1
    error_message = "private_endpoint must set exactly one connectivity mode."
  }
}

variable "region" {
  description = "AWS Region in which to manage the Runtime target. Defaults to the provider Region."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the CloudFormation stack."
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Optional create, update, and delete timeout overrides."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
