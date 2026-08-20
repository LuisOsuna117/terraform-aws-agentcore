variable "name" {
  description = "Name prefix for the example resources."
  type        = string
  default     = "agentcore-identity"
}

variable "region" {
  description = "AWS Region in which to create the resources."
  type        = string
  default     = "us-east-1"
}

variable "oauth_return_url" {
  description = "Allowed OAuth callback URL for the workload identity."
  type        = string
}

variable "oauth_discovery_url" {
  description = "OIDC discovery URL for the outbound OAuth provider."
  type        = string
}

variable "oauth_client_id" {
  description = "OAuth client ID stored through the provider write-only field."
  type        = string
  sensitive   = true
}

variable "oauth_client_secret" {
  description = "OAuth client secret stored through the provider write-only field."
  type        = string
  sensitive   = true
}

variable "credentials_version" {
  description = "Monotonically increasing version used to rotate OAuth credentials."
  type        = number
  default     = 1
}
