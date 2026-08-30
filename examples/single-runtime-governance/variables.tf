variable "aws_region" {
  description = "AWS Region in which to create the resources."
  type        = string
  default     = "us-east-1"
}

variable "image_uri" {
  description = "Digest-pinned ECR image URI for this Runtime."
  type        = string
}

variable "jwt_discovery_url" {
  description = "OIDC discovery URL used by the Runtime and Gateway."
  type        = string
}

variable "jwt_client_id" {
  description = "OAuth client allowed to invoke the Runtime and Gateway."
  type        = string
}

variable "evaluation_execution_role_arn" {
  description = "Execution role used by the online evaluation."
  type        = string
}
