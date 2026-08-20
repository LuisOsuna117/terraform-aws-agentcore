output "evaluators" {
  description = "Evaluator IDs and ARNs keyed by caller-defined name."
  value = {
    for key, evaluator in aws_bedrockagentcore_evaluator.this : key => {
      id  = evaluator.evaluator_id
      arn = evaluator.evaluator_arn
    }
  }
}

output "online_evaluations" {
  description = "Online evaluation IDs and ARNs keyed by caller-defined name."
  value = {
    for key, config in aws_bedrockagentcore_online_evaluation_config.this : key => {
      id  = config.online_evaluation_config_id
      arn = config.online_evaluation_config_arn
    }
  }
}
