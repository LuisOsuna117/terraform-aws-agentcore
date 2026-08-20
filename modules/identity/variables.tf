variable "name" {
  description = "Base name used for Identity resources when an item does not provide its own name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,31}$", var.name))
    error_message = "name must start with a letter, be at most 32 characters, and contain only letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Tags to apply to taggable Identity resources."
  type        = map(string)
  default     = {}
}

variable "workload_identities" {
  description = "Workload identities keyed by a stable caller-defined name."
  type = map(object({
    name                      = optional(string)
    allowed_oauth_return_urls = optional(set(string), [])
  }))
  default = {}
}

variable "api_key_credential_providers" {
  description = "API key credential provider metadata. Matching secrets are supplied separately through api_key_values."
  type = map(object({
    name           = optional(string)
    secret_version = number
  }))
  default = {}
}

variable "api_key_values" {
  description = "Write-only API keys keyed exactly like api_key_credential_providers. Values are not persisted in state by the AWS provider."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "oauth2_credential_providers" {
  description = "OAuth2 credential provider metadata. Matching credentials are supplied separately through oauth2_client_ids and oauth2_client_secrets."
  type = map(object({
    name                   = optional(string)
    vendor                 = string
    credentials_version    = number
    discovery_url          = optional(string)
    issuer                 = optional(string)
    authorization_endpoint = optional(string)
    token_endpoint         = optional(string)
    response_types         = optional(set(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for provider in values(var.oauth2_credential_providers) : contains([
        "CustomOauth2",
        "GithubOauth2",
        "GoogleOauth2",
        "Microsoft",
        "SalesforceOauth2",
        "SlackOauth2",
      ], provider.vendor)
    ])
    error_message = "vendor must be a supported AgentCore OAuth2 provider."
  }

  validation {
    condition = alltrue([
      for provider in values(var.oauth2_credential_providers) : provider.vendor != "CustomOauth2" || (
        provider.discovery_url != null || (
          provider.issuer != null &&
          provider.authorization_endpoint != null &&
          provider.token_endpoint != null
        )
      )
    ])
    error_message = "CustomOauth2 providers require discovery_url or explicit issuer, authorization_endpoint, and token_endpoint values."
  }
}

variable "oauth2_client_ids" {
  description = "Write-only OAuth2 client IDs keyed exactly like oauth2_credential_providers."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "oauth2_client_secrets" {
  description = "Write-only OAuth2 client secrets keyed exactly like oauth2_credential_providers."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "token_vault_cmk" {
  description = "Optional token-vault KMS configuration. CustomerManagedKey requires kms_key_arn; ServiceManagedKey does not."
  type = object({
    token_vault_id = optional(string, "default")
    key_type       = string
    kms_key_arn    = optional(string)
  })
  default = null

  validation {
    condition = var.token_vault_cmk == null || (
      contains(["CustomerManagedKey", "ServiceManagedKey"], var.token_vault_cmk.key_type) &&
      (var.token_vault_cmk.key_type != "CustomerManagedKey" || var.token_vault_cmk.kms_key_arn != null)
    )
    error_message = "token_vault_cmk.key_type must be CustomerManagedKey or ServiceManagedKey, and CustomerManagedKey requires kms_key_arn."
  }
}
