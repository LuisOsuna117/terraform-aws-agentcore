resource "aws_cloudformation_stack" "this" {
  name          = var.name
  template_body = var.template_body
  parameters    = var.parameters
  capabilities  = var.capabilities
  tags          = var.tags

  lifecycle {
    precondition {
      condition     = !can(regex("(?i)(secret|password|token)\\s*[:=]\\s*[^<{]", var.template_body))
      error_message = "Preview templates must reference secrets externally; inline secret-like values are forbidden."
    }
  }
}
