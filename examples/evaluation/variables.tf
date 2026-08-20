variable "aws_region" {
  description = "AWS Region in which to create resources."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for evaluation resources."
  type        = string
  default     = "evaluation-example"
}

variable "evaluator_lambda_arn" {
  description = "Lambda function implementing the code-based evaluator."
  type        = string
}

variable "evaluation_execution_role_arn" {
  description = "IAM role used by online evaluation."
  type        = string
}

variable "log_group_names" {
  description = "CloudWatch log groups containing AgentCore telemetry."
  type        = set(string)
}

variable "service_names" {
  description = "AgentCore service names to evaluate."
  type        = set(string)
}

variable "tags" {
  description = "Tags to apply to evaluation resources."
  type        = map(string)
  default     = {}
}
