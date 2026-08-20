variable "aws_region" {
  description = "AWS Region in which to create the resources."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for the example resources."
  type        = string
  default     = "identity-example"
}

variable "allowed_oauth_return_urls" {
  description = "Allowed OAuth2 callback URLs for the workload identity."
  type        = set(string)
  default     = ["http://127.0.0.1:8080/callback"]
}

variable "api_key" {
  description = "API key passed through the provider's write-only argument."
  type        = string
  sensitive   = true
}

variable "api_key_version" {
  description = "Increment to rotate the write-only API key."
  type        = number
  default     = 1
}

variable "oauth_client_id" {
  description = "OAuth2 client ID passed through a write-only argument."
  type        = string
  sensitive   = true
}

variable "oauth_client_secret" {
  description = "OAuth2 client secret passed through a write-only argument."
  type        = string
  sensitive   = true
}

variable "oauth_credentials_version" {
  description = "Increment to rotate the write-only OAuth2 credentials."
  type        = number
  default     = 1
}

variable "oauth_discovery_url" {
  description = "OpenID Connect discovery URL for the custom OAuth2 provider."
  type        = string
}

variable "tags" {
  description = "Tags to apply to taggable resources."
  type        = map(string)
  default     = {}
}
