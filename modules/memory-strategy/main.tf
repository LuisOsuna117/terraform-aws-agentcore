resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = (var.type == "CUSTOM") == (var.custom_configuration != null)
      error_message = "custom_configuration is required only when type is CUSTOM."
    }

    precondition {
      condition     = length(var.reflection_namespace_templates) == 0 || var.type == "EPISODIC"
      error_message = "reflection_namespace_templates may only be set for an EPISODIC strategy."
    }
  }
}

resource "aws_bedrockagentcore_memory_strategy" "this" {
  memory_id           = var.memory_id
  name                = var.name
  type                = var.type
  description         = var.description
  namespace_templates = [var.namespace_template]

  dynamic "configuration" {
    for_each = var.custom_configuration == null ? [] : [var.custom_configuration]
    content {
      type = configuration.value.type

      dynamic "consolidation" {
        for_each = configuration.value.consolidation == null ? [] : [configuration.value.consolidation]
        content {
          append_to_prompt = consolidation.value.append_to_prompt
          model_id         = consolidation.value.model_id
        }
      }

      dynamic "extraction" {
        for_each = configuration.value.extraction == null ? [] : [configuration.value.extraction]
        content {
          append_to_prompt = extraction.value.append_to_prompt
          model_id         = extraction.value.model_id
        }
      }

      dynamic "reflection" {
        for_each = configuration.value.reflection == null ? [] : [configuration.value.reflection]
        content {
          append_to_prompt    = reflection.value.append_to_prompt
          model_id            = reflection.value.model_id
          namespace_templates = reflection.value.namespace_templates
        }
      }
    }
  }

  dynamic "reflection_configuration" {
    for_each = length(var.reflection_namespace_templates) == 0 ? [] : [var.reflection_namespace_templates]
    content {
      namespace_templates = reflection_configuration.value
    }
  }

  depends_on = [terraform_data.validations]
}
