provider "aws" {
  region = var.aws_region
}

module "evaluation" {
  source = "../../modules/evaluation"

  name = var.name

  evaluators = {
    safety = {
      level = "TRACE"
      code_based = {
        lambda_arn = var.evaluator_lambda_arn
      }
    }
  }

  online_evaluations = {
    sampled = {
      execution_role_arn      = var.evaluation_execution_role_arn
      evaluator_keys          = ["safety"]
      log_group_names         = var.log_group_names
      service_names           = var.service_names
      sampling_percentage     = 10
      session_timeout_minutes = 15
    }
  }

  tags = var.tags
}
