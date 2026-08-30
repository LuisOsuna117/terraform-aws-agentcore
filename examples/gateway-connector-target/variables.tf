variable "aws_region" {
  description = "AWS Region containing the AgentCore Gateway."
  type        = string
  default     = "us-east-1"
}

variable "gateway_identifier" {
  description = "Existing AgentCore Gateway ID."
  type        = string
}

variable "allowed_domains" {
  description = "Administrator allowlist enforced by the Web Search target."
  type        = list(string)
  default     = ["docs.aws.amazon.com", "aws.amazon.com"]
}

variable "excluded_domains" {
  description = "Administrator denylist enforced by the Web Search target."
  type        = list(string)
  default     = []
}
