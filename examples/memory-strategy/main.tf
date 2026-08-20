provider "aws" {
  region = var.aws_region
}

module "memory_strategy" {
  source = "../../modules/memory-strategy"

  memory_id          = var.memory_id
  name               = "semantic"
  type               = "SEMANTIC"
  namespace_template = "/actors/{actorId}/sessions/{sessionId}"
}
