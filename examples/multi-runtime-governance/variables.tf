variable "aws_region" {
  description = "AWS Region in which to create resources."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix for the composed AgentCore resources."
  type        = string
  default     = "governed-agents"
}

variable "image_uri" {
  description = "Digest-pinned Amazon ECR image shared by both Runtime configurations."
  type        = string
}

variable "model_arns" {
  description = "Bedrock model or inference-profile ARNs each Runtime may invoke."
  type        = set(string)
}

variable "jwt_discovery_url" {
  description = "OIDC discovery URL used by the interactive Gateway and Runtime."
  type        = string
}

variable "jwt_allowed_clients" {
  description = "OAuth client IDs allowed to invoke the interactive lane."
  type        = set(string)
}

variable "automation_caller_role_arns" {
  description = "IAM role ARNs allowed to invoke the automation Gateway."
  type        = set(string)
}

variable "tags" {
  description = "Additional tags applied to module-managed resources."
  type        = map(string)
  default     = {}
}
