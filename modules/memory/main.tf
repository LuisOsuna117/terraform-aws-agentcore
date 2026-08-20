resource "aws_bedrockagentcore_memory" "this" {
  name                  = var.name
  event_expiry_duration = var.event_expiry_duration

  description               = var.description
  encryption_key_arn        = var.encryption_key_arn
  memory_execution_role_arn = var.memory_execution_role_arn

  tags = var.tags
}
