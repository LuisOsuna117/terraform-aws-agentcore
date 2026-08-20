variable "gateway_identifier" {
  description = "ID of the AgentCore Gateway that owns this target."
  type        = string
}

variable "name" {
  description = "Gateway Target name."
  type        = string
}

variable "description" {
  description = "Gateway Target description."
  type        = string
  default     = null
}

variable "target_type" {
  description = "Target type: HTTP_RUNTIME or MCP_SERVER."
  type        = string
  default     = "HTTP_RUNTIME"

  validation {
    condition     = contains(["HTTP_RUNTIME", "MCP_SERVER"], var.target_type)
    error_message = "target_type must be HTTP_RUNTIME or MCP_SERVER."
  }
}

variable "runtime_arn" {
  description = "AgentCore Runtime ARN used by an HTTP_RUNTIME target."
  type        = string
  default     = null
}

variable "runtime_qualifier" {
  description = "Runtime qualifier used by an HTTP_RUNTIME target."
  type        = string
  default     = "DEFAULT"
}

variable "mcp_endpoint" {
  description = "HTTPS MCP server endpoint used by an MCP_SERVER target."
  type        = string
  default     = null
}

variable "mcp_listing_mode" {
  description = "MCP server tool-listing mode."
  type        = string
  default     = null
}

variable "credential_mode" {
  description = "Outbound credential mode."
  type        = string
  default     = "GATEWAY_IAM_ROLE"

  validation {
    condition = contains([
      "JWT_PASSTHROUGH",
      "GATEWAY_IAM_ROLE",
      "CALLER_IAM_CREDENTIALS",
      "API_KEY",
      "OAUTH",
    ], var.credential_mode)
    error_message = "credential_mode must be a supported native Gateway credential mode."
  }
}

variable "signing_service" {
  description = "SigV4 service used by IAM credential modes."
  type        = string
  default     = null
}

variable "signing_region" {
  description = "SigV4 Region used by IAM credential modes."
  type        = string
  default     = null
}

variable "credential_provider_arn" {
  description = "AgentCore Identity credential provider ARN used by API_KEY or OAUTH."
  type        = string
  default     = null
}

variable "api_key_location" {
  description = "API key credential location."
  type        = string
  default     = null
}

variable "api_key_parameter_name" {
  description = "Header or query parameter name for API key credentials."
  type        = string
  default     = null
}

variable "api_key_prefix" {
  description = "Optional prefix added to the API key."
  type        = string
  default     = null
}

variable "oauth_grant_type" {
  description = "OAuth2 grant type."
  type        = string
  default     = null
}

variable "oauth_scopes" {
  description = "OAuth2 scopes requested from the credential provider."
  type        = list(string)
  default     = []
}

variable "oauth_default_return_url" {
  description = "Default OAuth2 return URL."
  type        = string
  default     = null
}

variable "oauth_custom_parameters" {
  description = "Additional OAuth2 parameters."
  type        = map(string)
  default     = {}
}

variable "allowed_query_parameters" {
  description = "Query parameters forwarded to the target."
  type        = set(string)
  default     = []
}

variable "allowed_request_headers" {
  description = "Request headers forwarded to the target."
  type        = set(string)
  default     = []
}

variable "allowed_response_headers" {
  description = "Response headers returned from the target."
  type        = set(string)
  default     = []
}
