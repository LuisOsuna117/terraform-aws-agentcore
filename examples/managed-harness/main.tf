provider "aws" {
  region = var.aws_region
}

module "managed_harness" {
  source = "../../modules/managed-harness"

  name               = var.name
  execution_role_arn = var.execution_role_arn
  model_id           = var.model_id
  system_prompt      = var.system_prompt

  max_iterations  = 8
  max_tokens      = 4096
  timeout_seconds = 300

  tags = var.tags
}
