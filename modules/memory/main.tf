resource "aws_bedrockagentcore_memory" "this" {
  name                  = var.name
  event_expiry_duration = var.event_expiry_duration

  description               = var.description
  encryption_key_arn        = var.encryption_key_arn
  memory_execution_role_arn = var.memory_execution_role_arn
  region                    = var.region

  dynamic "indexed_key" {
    for_each = var.indexed_keys
    content {
      key  = indexed_key.value.key
      type = indexed_key.value.type
    }
  }

  dynamic "stream_delivery_resources" {
    for_each = length(var.kinesis_streams) == 0 ? [] : [1]
    content {
      dynamic "resource" {
        for_each = var.kinesis_streams
        content {
          kinesis {
            data_stream_arn = resource.value.data_stream_arn

            dynamic "content_configuration" {
              for_each = resource.value.content_configurations
              content {
                type  = content_configuration.value.type
                level = content_configuration.value.level
              }
            }
          }
        }
      }
    }
  }

  tags = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
