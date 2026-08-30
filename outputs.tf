# ==============================================================================
# AgentCore Runtime
# ==============================================================================

output "agent_runtime_id" {
  description = "ID of the AgentCore runtime resource. Null when create_runtime = false."
  value       = var.create_runtime ? module.runtime[0].agent_runtime_id : null
}

output "agent_runtime_arn" {
  description = "ARN of the AgentCore runtime. Use this to grant invoke permissions to callers. Null when create_runtime = false."
  value       = var.create_runtime ? module.runtime[0].agent_runtime_arn : null
}

output "agent_runtime_name" {
  description = "Resolved name of the AgentCore runtime as registered with the Bedrock AgentCore API. Null when create_runtime = false."
  value       = var.create_runtime ? module.runtime[0].agent_runtime_name : null
}

output "agent_runtime_version" {
  description = "Version identifier of the deployed AgentCore runtime. Null when create_runtime = false."
  value       = var.create_runtime ? module.runtime[0].agent_runtime_version : null
}

output "agent_runtime_network_mode" {
  description = "Network mode of the runtime (PUBLIC or VPC). Null when create_runtime = false."
  value       = var.create_runtime ? var.network_mode : null
}

output "agent_runtime_workload_identity_arn" {
  description = "Workload identity ARN for the runtime. Use this to grant callers permission to obtain workload access tokens. Null when create_runtime = false."
  value       = var.create_runtime ? module.runtime[0].workload_identity_arn : null
}

output "agent_runtime_allowed_workload_identities" {
  description = "CUSTOM_JWT workload identities allowed to invoke the Runtime, including the module-created Gateway identity when opted in."
  value = local.effective_runtime_authorizer_configuration == null ? [] : try(
    local.effective_runtime_authorizer_configuration.workload_identities,
    [],
  )
}

# ==============================================================================
# AgentCore Code Interpreter
# ==============================================================================

output "code_interpreter_id" {
  description = "Unique identifier of the AgentCore Code Interpreter. Null when create_code_interpreter = false."
  value       = var.create_code_interpreter ? module.code_interpreter[0].code_interpreter_id : null
}

output "code_interpreter_arn" {
  description = "ARN of the AgentCore Code Interpreter. Null when create_code_interpreter = false."
  value       = var.create_code_interpreter ? module.code_interpreter[0].code_interpreter_arn : null
}

output "code_interpreter_name" {
  description = "Resolved name of the AgentCore Code Interpreter. Null when create_code_interpreter = false."
  value       = var.create_code_interpreter ? module.code_interpreter[0].code_interpreter_name : null
}

output "code_interpreter_network_mode" {
  description = "Network mode of the AgentCore Code Interpreter. Null when create_code_interpreter = false."
  value       = var.create_code_interpreter ? var.code_interpreter_network_mode : null
}

output "code_interpreter_execution_role_arn" {
  description = "ARN of the IAM execution role used by the AgentCore Code Interpreter. Null when create_code_interpreter = false."
  value       = var.create_code_interpreter ? module.code_interpreter[0].execution_role_arn : null
}

# ==============================================================================
# Image
# ==============================================================================

output "effective_image_uri" {
  description = "The container image URI used by the runtime. When create_build_pipeline = true this is the ECR repo URL + image_tag; when create_build_pipeline = false this is the caller-supplied image_uri."
  value       = local.effective_image_uri
}

# ==============================================================================
# IAM
# ==============================================================================

output "execution_role_arn" {
  description = "ARN of the IAM role used by the AgentCore runtime. Will equal var.execution_role_arn when create_execution_role = false."
  value       = local.execution_role_arn
}

output "execution_role_name" {
  description = "Name of the module-created execution role. Null when create_execution_role is false."
  value       = var.create_execution_role ? aws_iam_role.agent_execution[0].name : null
}

output "codebuild_role_arn" {
  description = "ARN of the IAM role used by the CodeBuild image-build project. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].codebuild_role_arn : null
}

# ==============================================================================
# ECR (create_build_pipeline = true only)
# ==============================================================================

output "ecr_repository_url" {
  description = "Full ECR repository URL (without tag). Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].ecr_repository_url : null
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].ecr_repository_arn : null
}

output "ecr_repository_name" {
  description = "Name of the ECR repository. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].ecr_repository_name : null
}

# ==============================================================================
# CodeBuild (create_build_pipeline = true only)
# ==============================================================================

output "codebuild_project_name" {
  description = "Name of the CodeBuild project. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].codebuild_project_name : null
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].codebuild_project_arn : null
}

output "codebuild_start_build_command" {
  description = "AWS CLI command to trigger a CodeBuild build manually. Copy-paste into your CI pipeline when trigger_build_on_apply = false. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].codebuild_start_build_command : null
}

# ==============================================================================
# S3 — Source Bucket (create_build_pipeline = true only)
# ==============================================================================

output "source_bucket_name" {
  description = "Name of the S3 bucket holding the agent source code archive. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].source_bucket_name : null
}

output "source_bucket_arn" {
  description = "ARN of the S3 source bucket. Null when create_build_pipeline = false."
  value       = var.create_build_pipeline ? module.build[0].source_bucket_arn : null
}

# ==============================================================================
# Memory (create_memory = true only)
# ==============================================================================

output "memory_arn" {
  description = "ARN of the AgentCore Memory resource. Null when create_memory = false."
  value       = var.create_memory ? module.memory[0].memory_arn : null
}

output "memory_id" {
  description = "Unique identifier of the AgentCore Memory resource. Null when create_memory = false."
  value       = var.create_memory ? module.memory[0].memory_id : null
}

output "memory_name" {
  description = "Name of the AgentCore Memory resource. Null when create_memory = false."
  value       = var.create_memory ? module.memory[0].memory_name : null
}

# ==============================================================================
# Gateway (create_gateway = true only)
# ==============================================================================

output "gateway_id" {
  description = "Unique identifier of the AgentCore Gateway. Null when create_gateway = false."
  value       = var.create_gateway ? module.gateway[0].gateway_id : null
}

output "gateway_arn" {
  description = "ARN of the AgentCore Gateway. Null when create_gateway = false."
  value       = var.create_gateway ? module.gateway[0].gateway_arn : null
}

output "gateway_url" {
  description = "URL endpoint of the AgentCore Gateway. Null when create_gateway = false."
  value       = var.create_gateway ? module.gateway[0].gateway_url : null
}

output "gateway_protocol_type" {
  description = "Effective Gateway aggregation protocol. MCP for aggregation gateways, null for general HTTP gateways or when create_gateway = false."
  value       = var.create_gateway ? module.gateway[0].gateway_protocol_type : null
}

output "gateway_workload_identity_arn" {
  description = "Workload identity ARN associated with the gateway. Null when create_gateway = false."
  value       = var.create_gateway ? module.gateway[0].workload_identity_arn : null
}

output "gateway_target_ids" {
  description = "Map of target keys to AgentCore Gateway target IDs. Empty when create_gateway = false."
  value = var.create_gateway ? merge(
    module.gateway[0].gateway_target_ids,
    var.gateway_attach_runtime_target ? {
      (local.gateway_runtime_target_key) = (
        var.gateway_runtime_target.schema != null && !local.gateway_runtime_uses_mcp ?
        module.gateway_runtime_schema_target[0].target_id :
        module.gateway_runtime_target[0].target_id
      )
    } : {},
  ) : {}
}

output "gateway_target_invocation_urls" {
  description = "Map of direct HTTP target keys to their path-routed Gateway invocation URLs. Empty when create_gateway is false."
  value = var.create_gateway ? merge(
    module.gateway[0].gateway_target_invocation_urls,
    var.gateway_attach_runtime_target && !local.gateway_runtime_uses_mcp ? {
      (local.gateway_runtime_target_key) = "${trimsuffix(module.gateway[0].gateway_url, "/")}/${local.gateway_runtime_target_name}/invocations"
    } : {},
  ) : {}
}

output "gateway_runtime_target_id" {
  description = "Gateway target ID for the module-created runtime target. Null when gateway_attach_runtime_target = false."
  value = var.create_gateway && var.gateway_attach_runtime_target ? (
    var.gateway_runtime_target.schema != null && !local.gateway_runtime_uses_mcp ?
    module.gateway_runtime_schema_target[0].target_id :
    module.gateway_runtime_target[0].target_id
  ) : null
}

output "gateway_role_arn" {
  description = "ARN of the IAM role used by the gateway. Null when create_gateway = false."
  value       = var.create_gateway ? module.gateway[0].role_arn : null
}

output "gateway_role_name" {
  description = "Name of the module-created gateway IAM role. Null when create_gateway = false."
  value       = var.create_gateway ? module.gateway[0].role_name : null
}

# ==============================================================================
# Resource policies
# ==============================================================================

output "resource_policies" {
  description = "Resource policies attached to the Runtime and Gateway created by this module call."
  value       = length(module.resource_policy) == 0 ? {} : module.resource_policy[0].resource_policies
}

# ==============================================================================
# Opt-in services
# ==============================================================================

output "policy_engine_id" {
  description = "ID of the Policy Engine created or supplied to this invocation."
  value       = local.effective_policy_engine_id
}

output "policy_engine_arn" {
  description = "ARN of the Policy Engine created or supplied to this invocation."
  value       = local.effective_policy_engine_arn
}

output "policy_arns" {
  description = "Cedar and Dogwood policy ARNs keyed by caller-defined name."
  value = merge(
    length(module.gateway_policies) == 0 ? {} : module.gateway_policies[0].policy_arns,
    { for key, stack in aws_cloudformation_stack.temporal_policy : key => stack.outputs["PolicyArn"] },
  )
}

output "browser_id" {
  description = "ID of the Browser, or null when disabled."
  value       = var.create_browser ? module.browser[0].browser_id : null
}

output "browser_arn" {
  description = "ARN of the Browser, or null when disabled."
  value       = var.create_browser ? module.browser[0].browser_arn : null
}

output "browser_profile_ids" {
  description = "Browser Profile IDs keyed by caller-defined name."
  value       = var.create_browser ? module.browser[0].profile_ids : {}
}

output "evaluators" {
  description = "Evaluator IDs and ARNs keyed by caller-defined name."
  value       = var.create_evaluations ? module.evaluation[0].evaluators : {}
}

output "online_evaluations" {
  description = "Online evaluation IDs and ARNs keyed by caller-defined name."
  value       = var.create_evaluations ? module.evaluation[0].online_evaluations : {}
}

output "gateway_connector_targets" {
  description = "Built-in connector target IDs keyed by caller-defined name."
  value = {
    for key, target in module.gateway_connector_target : key => {
      id                = target.target_id
      gateway_arn       = target.gateway_arn
      connector_id      = target.connector_id
      connector_version = target.connector_version
    }
  }
}
