resource "aws_bedrockagentcore_agent_runtime" "this" {
  agent_runtime_name = var.runtime_name
  description        = var.description
  role_arn           = var.execution_role_arn

  agent_runtime_artifact {
    container_configuration {
      container_uri = var.image_uri
    }
  }

  network_configuration {
    network_mode = var.network_mode
  }

  environment_variables = var.environment_variables
}
