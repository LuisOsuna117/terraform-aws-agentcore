variable "name" {
  description = "Name prefix for the example resources."
  type        = string
  default     = "agentcore-complete"
}

variable "region" {
  description = "AWS Region in which to create the resources."
  type        = string
  default     = "us-east-1"
}

variable "image_uri" {
  description = "Immutable ARM64 container image URI shared by both runtimes."
  type        = string
}

variable "operator_runtime_role_arn" {
  description = "IAM role ARN assumed by the JWT-authenticated Runtime."
  type        = string
}

variable "automation_runtime_role_arn" {
  description = "IAM role ARN assumed by the IAM-authenticated Runtime."
  type        = string
}

variable "human_gateway_role_arn" {
  description = "IAM role ARN assumed by the JWT-authenticated Gateway."
  type        = string
}

variable "automation_gateway_role_arn" {
  description = "IAM role ARN assumed by the IAM-authenticated Gateway."
  type        = string
}

variable "jwt_discovery_url" {
  description = "OIDC discovery URL used by the human Gateway and Runtime."
  type        = string
}

variable "jwt_client_id" {
  description = "OAuth client ID accepted by the human Gateway and Runtime."
  type        = string
}
