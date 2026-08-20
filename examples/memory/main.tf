provider "aws" {
  region = var.region
}

module "agentcore" {
  source = "../.."

  name = var.name

  memories = {
    conversation = {
      event_expiry_duration = 30
    }
  }

  memory_strategies = {
    semantic = {
      memory_key          = "conversation"
      type                = "SEMANTIC"
      namespace_templates = ["/actors/{actorId}"]
    }
  }

  tags = {
    Environment = "example"
    Terraform   = "true"
  }
}
