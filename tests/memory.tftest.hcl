mock_provider "aws" {}

run "memory_supports_indexes_and_kinesis_delivery" {
  command = plan

  module {
    source = "./modules/memory"
  }

  variables {
    name                  = "operations_memory"
    event_expiry_duration = 365
    indexed_keys = [{
      key  = "tenant_id"
      type = "STRING"
    }]
    kinesis_streams = [{
      data_stream_arn = "arn:aws:kinesis:us-east-1:123456789012:stream/agent-memory"
      content_configurations = [{
        type  = "MEMORY_RECORDS"
        level = "METADATA_ONLY"
      }]
    }]
    region = "us-east-1"
    timeouts = {
      create = "30m"
    }
  }

  assert {
    condition = contains([
      for indexed_key in aws_bedrockagentcore_memory.this.indexed_key :
      "${indexed_key.key}:${indexed_key.type}"
    ], "tenant_id:STRING")
    error_message = "Memory must preserve indexed keys."
  }

  assert {
    condition     = aws_bedrockagentcore_memory.this.stream_delivery_resources[0].resource[0].kinesis[0].data_stream_arn == "arn:aws:kinesis:us-east-1:123456789012:stream/agent-memory"
    error_message = "Memory must preserve Kinesis delivery resources."
  }
}
