output "evaluators" {
  description = "Created Evaluator IDs and ARNs."
  value       = module.evaluation.evaluators
}

output "online_evaluations" {
  description = "Created online evaluation IDs and ARNs."
  value       = module.evaluation.online_evaluations
}
