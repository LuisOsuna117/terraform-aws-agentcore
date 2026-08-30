# ==============================================================================
# Locals — Naming, Tagging, and Derived Values
# ==============================================================================

locals {
  # Normalise the runtime name: AgentCore requires underscores, not hyphens.
  runtime_name = replace(coalesce(var.runtime_name, var.name), "-", "_")

  # Code Interpreter follows the same naming constraint as Runtime.
  code_interpreter_name = replace(coalesce(var.code_interpreter_name, var.name), "-", "_")

  # ECR repository name falls back to var.name if not explicitly set.
  ecr_repository_name = coalesce(var.ecr_repository_name, var.name)

  # Agent source directory — allows callers to supply their own path.
  agent_source_dir = coalesce(var.agent_source_dir, "${path.root}/agent-code")

  # Execution role ARN — from the module-created role or the caller-supplied one.
  execution_role_arn = var.create_execution_role ? aws_iam_role.agent_execution[0].arn : var.execution_role_arn

  # Reuse the runtime execution role by default, while allowing a dedicated
  # Code Interpreter execution role for least-privilege deployments.
  code_interpreter_execution_role_arn = var.code_interpreter_execution_role_arn != null ? var.code_interpreter_execution_role_arn : local.execution_role_arn

  # Tags applied to every taggable resource.
  common_tags = merge(
    {
      Module    = "terraform-aws-agentcore"
      ManagedBy = "Terraform"
    },
    var.tags,
  )

  workload_identity_resource_arns = [
    "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default",
    "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/*",
  ]

  # The container image URI used by the runtime.
  # create_build_pipeline = true  → module ECR plus an optional immutable digest
  # create_build_pipeline = false → caller-supplied image_uri (BYO)
  effective_image_uri = var.create_build_pipeline ? (
    var.image_digest == null ? module.build[0].image_uri : "${module.build[0].ecr_repository_url}@${var.image_digest}"
  ) : var.image_uri

  effective_runtime_authorizer_configuration = var.runtime_authorizer_configuration == null ? null : {
    discovery_url              = var.runtime_authorizer_configuration.discovery_url
    allowed_audience           = var.runtime_authorizer_configuration.allowed_audience
    allowed_clients            = var.runtime_authorizer_configuration.allowed_clients
    allowed_scopes             = var.runtime_authorizer_configuration.allowed_scopes
    hosting_environment_arns   = var.runtime_authorizer_configuration.hosting_environment_arns
    custom_claims              = var.runtime_authorizer_configuration.custom_claims
    private_endpoint           = var.runtime_authorizer_configuration.private_endpoint
    private_endpoint_overrides = var.runtime_authorizer_configuration.private_endpoint_overrides
    workload_identities = var.runtime_trust_gateway_workload_identity ? distinct(concat(
      var.runtime_authorizer_configuration.workload_identities,
      [module.gateway[0].workload_identity_arn],
    )) : var.runtime_authorizer_configuration.workload_identities
  }

  # Optional self-target: attach the runtime created by this root module call to
  # the gateway created by this same call. The stable map key is "runtime".
  gateway_runtime_target_key  = "runtime"
  gateway_runtime_target_name = coalesce(var.gateway_runtime_target.name, local.gateway_runtime_target_key)
  gateway_runtime_uses_mcp    = var.server_protocol == "MCP"
  effective_gateway_protocol_type = (
    var.gateway_protocol_type != null ? var.gateway_protocol_type :
    var.gateway_attach_runtime_target && local.gateway_runtime_uses_mcp ? "MCP" : null
  )
  gateway_runtime_arn       = try(module.runtime[0].agent_runtime_arn, null)
  gateway_runtime_arn_parts = local.gateway_runtime_arn == null ? [] : split(":", local.gateway_runtime_arn)
  gateway_runtime_resource_parts = length(local.gateway_runtime_arn_parts) <= 5 ? [] : split(
    "/",
    join(":", slice(local.gateway_runtime_arn_parts, 5, length(local.gateway_runtime_arn_parts))),
  )
  gateway_runtime_id = length(local.gateway_runtime_resource_parts) > 1 ? element(
    split(":", element(local.gateway_runtime_resource_parts, 1)),
    0,
  ) : null
  gateway_runtime_endpoint = local.gateway_runtime_id == null ? null : format(
    "https://bedrock-agentcore.%s.%s/runtimes/%s/invocations?qualifier=%s&accountId=%s",
    data.aws_region.current.region,
    data.aws_partition.current.dns_suffix,
    urlencode(local.gateway_runtime_id),
    urlencode(coalesce(var.gateway_runtime_target.qualifier, "DEFAULT")),
    element(local.gateway_runtime_arn_parts, 4),
  )

  gateway_runtime_target = var.gateway_attach_runtime_target && var.create_runtime ? {
    (local.gateway_runtime_target_key) = {
      name        = local.gateway_runtime_target_name
      description = var.gateway_runtime_target.description
      region      = var.gateway_runtime_target.region
      target_configuration = merge(
        local.gateway_runtime_uses_mcp ? {
          mcp = {
            mcp_server = {
              endpoint = local.gateway_runtime_endpoint
            }
          }
        } : {},
        local.gateway_runtime_uses_mcp ? {} : {
          http = {
            agentcore_runtime = {
              arn       = local.gateway_runtime_arn
              qualifier = coalesce(var.gateway_runtime_target.qualifier, "DEFAULT")
            }
          }
        },
      )
      credential_provider_configuration = var.gateway_runtime_target.credential_provider_configuration
      metadata_configuration            = var.gateway_runtime_target.metadata_configuration
      private_endpoint                  = var.gateway_runtime_target.private_endpoint
      timeouts                          = var.gateway_runtime_target.timeouts
    }
  } : {}

  gateway_target_names = [for key, target in var.gateway_targets : coalesce(try(target.name, null), key)]

  gateway_resource_policy_role_arns = var.gateway_resource_policy_configuration == null ? [] : sort(tolist(var.gateway_resource_policy_configuration.role_arns))
  runtime_resource_policy_role_arns = var.runtime_resource_policy_configuration == null ? [] : sort(distinct(compact(concat(
    tolist(var.runtime_resource_policy_configuration.role_arns),
    var.runtime_resource_policy_configuration.allow_gateway_role ? [try(module.gateway[0].role_arn, null)] : [],
  ))))

  gateway_resource_policy = var.gateway_resource_policy_configuration == null ? null : jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      length(local.gateway_resource_policy_role_arns) == 0 ? [] : [{
        Sid       = "AllowConfiguredRoles"
        Effect    = "Allow"
        Principal = { AWS = local.gateway_resource_policy_role_arns }
        Action    = "bedrock-agentcore:InvokeGateway"
        Resource  = try(module.gateway[0].gateway_arn, null)
      }],
      [merge(
        {
          Sid       = length(local.gateway_resource_policy_role_arns) == 0 ? "DenyAllCallers" : "DenyUnlistedCallers"
          Effect    = "Deny"
          Principal = "*"
          Action    = "bedrock-agentcore:InvokeGateway"
          Resource  = try(module.gateway[0].gateway_arn, null)
        },
        length(local.gateway_resource_policy_role_arns) == 0 ? {} : {
          Condition = {
            ArnNotEquals = { "aws:PrincipalArn" = local.gateway_resource_policy_role_arns }
          }
        },
      )],
    )
  })

  runtime_resource_policy = var.runtime_resource_policy_configuration == null ? null : jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      length(local.runtime_resource_policy_role_arns) == 0 ? [] : [{
        Sid       = "AllowConfiguredRoles"
        Effect    = "Allow"
        Principal = { AWS = local.runtime_resource_policy_role_arns }
        Action    = "bedrock-agentcore:InvokeAgentRuntime"
        Resource  = try(module.runtime[0].agent_runtime_arn, null)
      }],
      [merge(
        {
          Sid       = length(local.runtime_resource_policy_role_arns) == 0 ? "DenyAllCallers" : "DenyUnlistedCallers"
          Effect    = "Deny"
          Principal = "*"
          Action    = "bedrock-agentcore:InvokeAgentRuntime"
          Resource  = try(module.runtime[0].agent_runtime_arn, null)
        },
        length(local.runtime_resource_policy_role_arns) == 0 ? {} : {
          Condition = {
            ArnNotEquals = { "aws:PrincipalArn" = local.runtime_resource_policy_role_arns }
          }
        },
      )],
    )
  })

  root_resource_policies = merge(
    local.gateway_resource_policy == null ? {} : {
      gateway = {
        resource_arn = try(module.gateway[0].gateway_arn, null)
        policy       = local.gateway_resource_policy
      }
    },
    local.runtime_resource_policy == null ? {} : {
      runtime = {
        resource_arn = try(module.runtime[0].agent_runtime_arn, null)
        policy       = local.runtime_resource_policy
      }
    },
  )
}

locals {
  effective_policy_engine_id  = var.create_policy_engine ? module.policy_engine[0].policy_engine_id : var.policy_engine_id
  effective_policy_engine_arn = var.create_policy_engine ? module.policy_engine[0].policy_engine_arn : var.policy_engine_arn

  effective_gateway_policy_engine_configuration = var.gateway_policy_engine_mode == null ? var.gateway_policy_engine_configuration : {
    arn  = local.effective_policy_engine_arn
    mode = var.gateway_policy_engine_mode
  }

  runtime_environment_binding_values = {
    for name, source in var.runtime_environment_bindings : name => (
      source == "memory_id" ? module.memory[0].memory_id :
      module.browser[0].browser_id
    )
  }

  rendered_gateway_policies = {
    for key, policy in var.gateway_policy_templates : key => {
      name        = policy.name
      description = policy.description
      cedar_statement = templatestring(policy.statement_template, merge(policy.template_values, {
        gateway_arn = module.gateway[0].gateway_arn
      }))
      validation_mode = policy.validation_mode
    }
  }

  rendered_temporal_policies = {
    for key, policy in var.temporal_policy_templates : key => {
      name        = policy.name
      description = policy.description
      statement = templatestring(policy.statement_template, merge(policy.template_values, {
        gateway_arn = module.gateway[0].gateway_arn
      }))
      enforcement_mode = policy.enforcement_mode
      validation_mode  = policy.validation_mode
    }
  }

  effective_online_evaluations = {
    for key, evaluation in var.online_evaluations : key => {
      name               = try(evaluation.name, null)
      description        = try(evaluation.description, null)
      execution_role_arn = evaluation.execution_role_arn
      evaluator_keys     = try(toset(evaluation.evaluator_keys), toset([]))
      evaluator_ids      = try(toset(evaluation.evaluator_ids), toset([]))
      log_group_names = try(evaluation.use_runtime, false) ? toset([
        "/aws/bedrock-agentcore/runtimes/${module.runtime[0].agent_runtime_id}-DEFAULT"
      ]) : try(toset(evaluation.log_group_names), toset([]))
      service_names = try(evaluation.use_runtime, false) ? toset([
        "${module.runtime[0].agent_runtime_name}.DEFAULT"
      ]) : try(toset(evaluation.service_names), toset([]))
      sampling_percentage     = evaluation.sampling_percentage
      session_timeout_minutes = evaluation.session_timeout_minutes
      enable_on_create        = try(evaluation.enable_on_create, true)
      region                  = try(evaluation.region, null)
      filters                 = try(evaluation.filters, [])
      timeouts                = try(evaluation.timeouts, null)
    }
  }
}

# ==============================================================================
# Cross-variable Validations
# (terraform_data is a built-in resource — no external provider required)
# ==============================================================================

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition = var.create_build_pipeline || !var.create_runtime || length(compact([
        var.image_uri == null ? "" : "image_uri",
        var.runtime_code_configuration == null ? "" : "runtime_code_configuration",
      ])) == 1
      error_message = "When create_runtime is true and create_build_pipeline is false, configure exactly one of image_uri or runtime_code_configuration."
    }

    precondition {
      condition     = !var.create_build_pipeline || (var.image_uri == null && var.runtime_code_configuration == null)
      error_message = "image_uri and runtime_code_configuration must be null when create_build_pipeline is true; use image_digest for immutable deployment from the module repository."
    }

    precondition {
      condition     = var.create_build_pipeline || var.image_digest == null
      error_message = "image_digest requires create_build_pipeline = true."
    }

    precondition {
      condition     = var.create_execution_role || !var.create_runtime || var.execution_role_arn != null
      error_message = "execution_role_arn must be provided when create_runtime = true and create_execution_role = false."
    }

    precondition {
      condition     = !(var.network_mode == "VPC" && (length(var.vpc_security_group_ids) == 0 || length(var.vpc_subnet_ids) == 0))
      error_message = "vpc_security_group_ids and vpc_subnet_ids must both be non-empty when network_mode = \"VPC\"."
    }

    precondition {
      condition     = !var.create_code_interpreter || var.code_interpreter_network_mode != "SANDBOX" || local.code_interpreter_execution_role_arn != null
      error_message = "A Code Interpreter execution role is required in SANDBOX mode. Enable create_execution_role, set execution_role_arn, or set code_interpreter_execution_role_arn."
    }

    precondition {
      condition     = !var.create_code_interpreter || var.code_interpreter_network_mode != "VPC" || (length(var.code_interpreter_vpc_security_group_ids) > 0 && length(var.code_interpreter_vpc_subnet_ids) > 0)
      error_message = "code_interpreter_vpc_security_group_ids and code_interpreter_vpc_subnet_ids must both be non-empty when code_interpreter_network_mode = \"VPC\"."
    }

    precondition {
      condition     = var.create_gateway || length(var.gateway_targets) == 0
      error_message = "gateway_targets requires create_gateway = true."
    }

    precondition {
      condition     = !var.gateway_attach_runtime_target || var.create_runtime
      error_message = "gateway_attach_runtime_target = true requires create_runtime = true."
    }

    precondition {
      condition     = !var.gateway_attach_runtime_target || var.create_gateway
      error_message = "gateway_attach_runtime_target = true requires create_gateway = true."
    }

    precondition {
      condition     = var.gateway_runtime_target.schema == null || !local.gateway_runtime_uses_mcp
      error_message = "gateway_runtime_target.schema is supported only for HTTP Runtime targets."
    }

    precondition {
      condition     = !var.gateway_attach_runtime_target || !contains(keys(var.gateway_targets), local.gateway_runtime_target_key)
      error_message = "gateway_targets cannot use key \"runtime\" when gateway_attach_runtime_target = true; that key is reserved for the module-created runtime target."
    }

    precondition {
      condition     = !var.gateway_attach_runtime_target || !contains(local.gateway_target_names, local.gateway_runtime_target_name)
      error_message = "gateway_runtime_target.name must not collide with any resolved gateway target name."
    }

    precondition {
      condition = !var.gateway_attach_runtime_target || alltrue([
        for target in values(var.gateway_targets) :
        local.gateway_runtime_uses_mcp == contains(try(keys(target.target_configuration), []), "mcp")
      ])
      error_message = "The attached Runtime target and gateway_targets must use the same HTTP or MCP Gateway protocol."
    }

    precondition {
      condition     = var.gateway_resource_policy_configuration == null || (var.create_gateway && var.gateway_authorizer_type == "AWS_IAM")
      error_message = "gateway_resource_policy_configuration requires create_gateway = true and gateway_authorizer_type = \"AWS_IAM\"."
    }

    precondition {
      condition     = var.runtime_resource_policy_configuration == null || (var.create_runtime && var.runtime_authorizer_configuration == null)
      error_message = "runtime_resource_policy_configuration requires an IAM-authorized module-created Runtime."
    }

    precondition {
      condition     = var.runtime_resource_policy_configuration == null ? true : (!var.runtime_resource_policy_configuration.allow_gateway_role || var.create_gateway)
      error_message = "runtime_resource_policy_configuration.allow_gateway_role requires create_gateway = true."
    }

    precondition {
      condition = !var.runtime_trust_gateway_workload_identity || (
        var.create_runtime &&
        var.create_gateway &&
        var.gateway_attach_runtime_target &&
        var.runtime_authorizer_configuration != null &&
        try(var.gateway_runtime_target.credential_provider_configuration.jwt_passthrough, false)
      )
      error_message = "runtime_trust_gateway_workload_identity requires a module-created Runtime and Gateway, an attached Runtime target using JWT passthrough, and runtime_authorizer_configuration."
    }

    precondition {
      condition     = !var.create_policy_engine || (var.policy_engine_id == null && var.policy_engine_arn == null)
      error_message = "policy_engine_id and policy_engine_arn must be null when create_policy_engine = true."
    }

    precondition {
      condition     = length(var.gateway_policy_templates) == 0 && length(var.temporal_policy_templates) == 0 || (var.create_gateway && local.effective_policy_engine_id != null)
      error_message = "Policy templates require a Gateway and a created or supplied Policy Engine ID."
    }

    precondition {
      condition     = var.gateway_policy_engine_mode == null || (var.create_gateway && local.effective_policy_engine_arn != null)
      error_message = "gateway_policy_engine_mode requires a Gateway and a created or supplied Policy Engine ARN."
    }

    precondition {
      condition     = length(setintersection(toset(keys(var.gateway_policy_templates)), toset(keys(var.temporal_policy_templates)))) == 0
      error_message = "Cedar and Dogwood policy maps must use distinct keys."
    }

    precondition {
      condition = alltrue([
        for source in values(var.runtime_environment_bindings) :
        source == "memory_id" ? var.create_memory :
        var.create_browser
      ])
      error_message = "Each Runtime environment binding must reference a resource enabled by this invocation."
    }

    precondition {
      condition     = !var.runtime_memory_access_enabled || (var.create_runtime && var.create_execution_role && var.create_memory)
      error_message = "runtime_memory_access_enabled requires a module-created Runtime role and Memory."
    }

    precondition {
      condition     = !var.runtime_browser_access_enabled || (var.create_runtime && var.create_execution_role && var.create_browser)
      error_message = "runtime_browser_access_enabled requires a module-created Runtime role and Browser."
    }

    precondition {
      condition = alltrue([
        for evaluation in values(var.online_evaluations) :
        !try(evaluation.use_runtime, false) || var.create_runtime
      ])
      error_message = "An online evaluation with use_runtime = true requires create_runtime = true."
    }

    precondition {
      condition     = !var.create_gateway_connectors || var.create_gateway
      error_message = "create_gateway_connectors requires create_gateway = true."
    }

  }
}

# ==============================================================================
# Build submodule
#
# Provisions ECR, S3, CodeBuild, and build IAM only when explicitly enabled.
# ==============================================================================

module "build" {
  count  = var.create_build_pipeline ? 1 : 0
  source = "./modules/build"

  name                = var.name
  common_tags         = local.common_tags
  ecr_repository_name = local.ecr_repository_name

  # ECR
  ecr_image_tag_mutability = var.ecr_image_tag_mutability
  ecr_scan_on_push         = var.ecr_scan_on_push
  ecr_lifecycle_keep_count = var.ecr_lifecycle_keep_count
  ecr_force_delete         = var.ecr_force_delete
  ecr_pull_principals      = var.ecr_pull_principals

  # S3
  agent_source_dir            = local.agent_source_dir
  source_bucket_force_destroy = var.source_bucket_force_destroy

  # CodeBuild
  image_tag                   = var.image_tag
  codebuild_compute_type      = var.codebuild_compute_type
  codebuild_environment_image = var.codebuild_environment_image
  codebuild_environment_type  = var.codebuild_environment_type
  codebuild_build_timeout     = var.codebuild_build_timeout
  trigger_build_on_apply      = var.trigger_build_on_apply

  depends_on = [terraform_data.validations]
}

# ==============================================================================
# Runtime Submodule
# ==============================================================================

module "runtime" {
  count  = var.create_runtime ? 1 : 0
  source = "./modules/runtime"

  runtime_name       = local.runtime_name
  description        = var.description
  execution_role_arn = local.execution_role_arn
  image_uri          = local.effective_image_uri
  code_configuration = var.runtime_code_configuration
  filesystems        = var.runtime_filesystems
  network_mode       = var.network_mode

  # VPC networking (only used when network_mode = "VPC")
  vpc_security_group_ids = var.vpc_security_group_ids
  vpc_subnet_ids         = var.vpc_subnet_ids

  authorizer_configuration = local.effective_runtime_authorizer_configuration

  # Lifecycle (optional)
  idle_runtime_session_timeout = var.idle_runtime_session_timeout
  max_lifetime                 = var.max_lifetime

  # Protocol and headers (optional)
  server_protocol          = var.server_protocol
  request_header_allowlist = var.request_header_allowlist
  region                   = var.runtime_region
  timeouts                 = var.runtime_timeouts

  # AWS_REGION and AWS_DEFAULT_REGION are injected automatically.
  # Callers can append additional variables via var.environment_variables.
  environment_variables = merge(
    {
      AWS_REGION         = data.aws_region.current.region
      AWS_DEFAULT_REGION = data.aws_region.current.region
    },
    var.create_code_interpreter ? {
      # Module-defined convention: agent code can read this value to start and
      # invoke sessions without hard-coding the generated resource identifier.
      BEDROCK_AGENTCORE_CODE_INTERPRETER_ID = module.code_interpreter[0].code_interpreter_id
    } : {},
    var.environment_variables,
    local.runtime_environment_binding_values,
  )

  tags = local.common_tags

  depends_on = [
    terraform_data.validations,
    module.build,
    aws_iam_role_policy.agent_execution,
    aws_iam_role_policy.code_interpreter_invoke,
    aws_iam_role_policy_attachment.agent_execution_managed,
    aws_iam_role_policy_attachment.agent_execution_additional,
  ]
}

# ==============================================================================
# Code Interpreter Submodule
# ==============================================================================

module "code_interpreter" {
  count  = var.create_code_interpreter ? 1 : 0
  source = "./modules/code-interpreter"

  name               = local.code_interpreter_name
  description        = var.code_interpreter_description
  execution_role_arn = local.code_interpreter_execution_role_arn
  network_mode       = var.code_interpreter_network_mode

  vpc_security_group_ids = var.code_interpreter_vpc_security_group_ids
  vpc_subnet_ids         = var.code_interpreter_vpc_subnet_ids
  certificate_secret_arn = var.code_interpreter_certificate_secret_arn
  region                 = var.code_interpreter_region
  timeouts               = var.code_interpreter_timeouts
  tags                   = local.common_tags

  depends_on = [
    terraform_data.validations,
    aws_iam_role_policy.agent_execution,
    aws_iam_role_policy_attachment.agent_execution_managed,
    aws_iam_role_policy_attachment.agent_execution_additional,
  ]
}

# ==============================================================================
# Memory Submodule
# ==============================================================================

module "memory" {
  count  = var.create_memory ? 1 : 0
  source = "./modules/memory"

  name                      = replace(coalesce(var.memory_name, var.name), "-", "_")
  event_expiry_duration     = var.memory_event_expiry_duration
  description               = var.memory_description
  encryption_key_arn        = var.memory_encryption_key_arn
  memory_execution_role_arn = var.memory_execution_role_arn
  indexed_keys              = var.memory_indexed_keys
  kinesis_streams           = var.memory_kinesis_streams
  region                    = var.memory_region
  timeouts                  = var.memory_timeouts
  tags                      = local.common_tags
}

# ==============================================================================
# Gateway Submodule
# ==============================================================================

module "gateway" {
  count  = var.create_gateway ? 1 : 0
  source = "./modules/gateway"

  name                        = coalesce(var.gateway_name, var.name)
  description                 = var.gateway_description
  create_role                 = var.gateway_create_role
  role_arn                    = var.gateway_role_arn
  role_policy_arns            = var.gateway_role_policy_arns
  role_policy_statements      = var.gateway_role_policy_statements
  authorizer_type             = var.gateway_authorizer_type
  authorizer_configuration    = var.gateway_authorizer_configuration
  protocol_type               = local.effective_gateway_protocol_type
  protocol_configuration      = var.gateway_protocol_configuration
  policy_engine_configuration = local.effective_gateway_policy_engine_configuration
  interceptor_configurations  = var.gateway_interceptor_configurations
  targets                     = var.gateway_targets
  runtime_invoke_arns         = var.gateway_runtime_invoke_arns
  kms_key_arn                 = var.gateway_kms_key_arn
  exception_level             = var.gateway_exception_level
  region                      = var.gateway_region
  timeouts                    = var.gateway_timeouts
  tags                        = local.common_tags
}

# The Runtime self-target is deliberately created after both the Gateway and
# Runtime. Keeping it outside module.gateway avoids a Gateway <-> Runtime graph
# cycle when CUSTOM_JWT restricts the Runtime to this Gateway workload.
module "gateway_runtime_target" {
  count = (
    var.create_gateway &&
    var.create_runtime &&
    var.gateway_attach_runtime_target &&
    (var.gateway_runtime_target.schema == null || local.gateway_runtime_uses_mcp)
  ) ? 1 : 0
  source = "./modules/gateway-target"

  gateway_identifier                = module.gateway[0].gateway_id
  name                              = local.gateway_runtime_target_name
  description                       = var.gateway_runtime_target.description
  region                            = var.gateway_runtime_target.region
  target_configuration              = local.gateway_runtime_target[local.gateway_runtime_target_key].target_configuration
  credential_provider_configuration = var.gateway_runtime_target.credential_provider_configuration
  metadata_configuration            = var.gateway_runtime_target.metadata_configuration
  private_endpoint                  = var.gateway_runtime_target.private_endpoint
  timeouts                          = var.gateway_runtime_target.timeouts
}

# AWS Provider releases through 6.62 do not expose the HTTP Runtime schema
# block. Keep the provider gap isolated so schema-less targets remain native
# and this module can move back to the native resource without changing the
# root input contract.
module "gateway_runtime_schema_target" {
  count = (
    var.create_gateway &&
    var.create_runtime &&
    var.gateway_attach_runtime_target &&
    var.gateway_runtime_target.schema != null &&
    !local.gateway_runtime_uses_mcp
  ) ? 1 : 0
  source = "./modules/gateway-runtime-target-schema"

  gateway_identifier                = module.gateway[0].gateway_id
  name                              = local.gateway_runtime_target_name
  description                       = var.gateway_runtime_target.description
  runtime_arn                       = local.gateway_runtime_arn
  qualifier                         = coalesce(var.gateway_runtime_target.qualifier, "DEFAULT")
  schema                            = var.gateway_runtime_target.schema
  credential_provider_configuration = var.gateway_runtime_target.credential_provider_configuration
  metadata_configuration            = var.gateway_runtime_target.metadata_configuration
  private_endpoint                  = var.gateway_runtime_target.private_endpoint
  region                            = var.gateway_runtime_target.region
  tags                              = local.common_tags
  timeouts                          = var.gateway_runtime_target.timeouts
}

# module.gateway cannot infer this permission after the self-target is split
# from it. Grant it only to a module-created Gateway role when the target uses
# that role; existing roles remain caller-owned and JWT passthrough receives no
# unnecessary Runtime invocation grant.
resource "aws_iam_role_policy" "gateway_runtime_invoke" {
  count = (
    var.create_gateway &&
    var.create_runtime &&
    var.gateway_attach_runtime_target &&
    var.gateway_create_role &&
    try(var.gateway_runtime_target.credential_provider_configuration.gateway_iam_role, null) != null
  ) ? 1 : 0

  name = "${coalesce(var.gateway_name, var.name)}-runtime-invoke"
  role = var.gateway_create_role ? module.gateway[0].role_name : element(reverse(split("/", var.gateway_role_arn)), 0)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "InvokeAttachedAgentCoreRuntime"
      Effect = "Allow"
      Action = ["bedrock-agentcore:InvokeAgentRuntime"]
      Resource = [
        local.gateway_runtime_arn,
        "${local.gateway_runtime_arn}/runtime-endpoint/*",
      ]
    }]
  })
}

# ==============================================================================
# Resource policies for resources created by this root module call
# ==============================================================================

module "resource_policy" {
  count  = length(local.root_resource_policies) > 0 ? 1 : 0
  source = "./modules/policy"

  name                 = var.name
  create_policy_engine = false
  resource_policies    = local.root_resource_policies
}

# ==============================================================================
# Opt-in services owned by this module invocation
# ==============================================================================

module "policy_engine" {
  count  = var.create_policy_engine ? 1 : 0
  source = "./modules/policy"

  name                 = coalesce(var.policy_engine_name, var.name)
  create_policy_engine = true
  description          = var.policy_engine_description
  policies             = {}
  tags                 = local.common_tags
}

module "gateway_policies" {
  count  = length(local.rendered_gateway_policies) > 0 ? 1 : 0
  source = "./modules/policy"

  name                 = coalesce(var.policy_engine_name, var.name)
  create_policy_engine = false
  policy_engine_id     = local.effective_policy_engine_id
  policies             = local.rendered_gateway_policies
  tags                 = local.common_tags
}

resource "aws_cloudformation_stack" "temporal_policy" {
  for_each = local.rendered_temporal_policies

  name = "agentcore-policy-${substr(sha1("${local.effective_policy_engine_id}:${each.key}"), 0, 12)}"
  template_body = jsonencode({
    AWSTemplateFormatVersion = "2010-09-09"
    Resources = {
      Policy = {
        Type = "AWS::BedrockAgentCore::Policy"
        Properties = {
          Name            = replace(coalesce(each.value.name, each.key), "-", "_")
          Description     = each.value.description
          PolicyEngineId  = local.effective_policy_engine_id
          EnforcementMode = each.value.enforcement_mode
          ValidationMode  = each.value.validation_mode
          Definition = {
            Policy = {
              Statement = each.value.statement
            }
          }
        }
      }
    }
    Outputs = {
      PolicyArn = {
        Value = { "Fn::GetAtt" = ["Policy", "PolicyArn"] }
      }
    }
  })

  tags = local.common_tags
}

module "browser" {
  count  = var.create_browser ? 1 : 0
  source = "./modules/browser"

  name                    = coalesce(var.browser_name, var.name)
  create_browser          = true
  description             = var.browser_description
  execution_role_arn      = var.browser_execution_role_arn
  network_mode            = var.browser_network_mode
  vpc_security_group_ids  = var.browser_vpc_security_group_ids
  vpc_subnet_ids          = var.browser_vpc_subnet_ids
  browser_signing_enabled = var.browser_signing_enabled
  recording               = var.browser_recording
  certificate_secret_arn  = var.browser_certificate_secret_arn
  enterprise_policy       = var.browser_enterprise_policy
  profiles                = var.browser_profiles
  tags                    = local.common_tags
}

module "evaluation" {
  count  = var.create_evaluations ? 1 : 0
  source = "./modules/evaluation"

  name               = var.name
  evaluators         = var.evaluators
  online_evaluations = local.effective_online_evaluations
  tags               = local.common_tags
}

module "gateway_connector_target" {
  for_each = var.create_gateway_connectors ? var.gateway_connector_targets : {}
  source   = "./modules/gateway-connector-target"

  gateway_identifier    = module.gateway[0].gateway_id
  name                  = coalesce(each.value.name, each.key)
  description           = each.value.description
  connector_id          = each.value.connector_id
  connector_version     = each.value.connector_version
  configurations        = each.value.configurations
  region                = each.value.region
  log_retention_in_days = each.value.log_retention_in_days
  timeouts              = each.value.timeouts
  tags                  = merge(local.common_tags, each.value.tags)
}

# ==============================================================================
# Data Sources
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# AgentCore Execution Role
#
# Set create_execution_role = false and supply execution_role_arn to reuse an
# existing role instead of creating one.
# ==============================================================================

resource "aws_iam_role" "agent_execution" {
  count = var.create_execution_role ? 1 : 0

  name = "${var.name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AgentCoreAssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "bedrock-agentcore.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"
        }
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${var.name}-execution-role"
  })
}

# Optional AWS-managed policy. Disabled by default because it is broader than
# the execution role baseline assembled below.
resource "aws_iam_role_policy_attachment" "agent_execution_managed" {
  count = var.create_execution_role && var.attach_bedrock_fullaccess_policy ? 1 : 0

  role       = aws_iam_role.agent_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/BedrockAgentCoreFullAccess"
}

# Caller-supplied managed policies — useful when an existing managed policy is
# already the source of truth for the runtime's permissions.
resource "aws_iam_role_policy_attachment" "agent_execution_additional" {
  for_each = var.create_execution_role ? var.additional_iam_policy_arns : toset([])

  role       = aws_iam_role.agent_execution[0].name
  policy_arn = each.value
}

# Inline policy — least-privilege baseline plus any caller-supplied statements.
resource "aws_iam_role_policy" "agent_execution" {
  count = var.create_execution_role ? 1 : 0

  name = "${var.name}-execution-policy"
  role = aws_iam_role.agent_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # ECR — pull the agent container image (create_build_pipeline = true only).
      # When create_build_pipeline = false, callers grant their own pull
      # permissions via additional_iam_statements if the image is in a private
      # registry.
      var.create_build_pipeline ? [
        {
          Sid    = "ECRImagePull"
          Effect = "Allow"
          Action = [
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchCheckLayerAvailability",
          ]
          Resource = module.build[0].ecr_repository_arn
        },
      ] : [],
      [
        {
          Sid      = "ECRAuthToken"
          Effect   = "Allow"
          Action   = ["ecr:GetAuthorizationToken"]
          Resource = "*"
        },
        # CloudWatch Logs — runtime stdout/stderr
        # DescribeLogGroups requires a broad log-group:* resource to function correctly.
        {
          Sid      = "CloudWatchLogsDescribeGroups"
          Effect   = "Allow"
          Action   = ["logs:DescribeLogGroups"]
          Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
        },
        # CreateLogGroup/DescribeLogStreams are scoped to the agentcore log group.
        {
          Sid    = "CloudWatchLogsGroup"
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:DescribeLogStreams",
          ]
          Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*"
        },
        # CreateLogStream/PutLogEvents must target the log-stream ARN (requires :log-stream:* suffix).
        {
          Sid    = "CloudWatchLogsStream"
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*:log-stream:*"
        },
        # X-Ray — distributed tracing
        {
          Sid    = "XRayTracing"
          Effect = "Allow"
          Action = [
            "xray:PutTraceSegments",
            "xray:PutTelemetryRecords",
            "xray:GetSamplingRules",
            "xray:GetSamplingTargets",
          ]
          Resource = "*"
        },
        # CloudWatch Metrics — scoped to the agentcore namespace
        {
          Sid      = "CloudWatchMetrics"
          Effect   = "Allow"
          Action   = ["cloudwatch:PutMetricData"]
          Resource = "*"
          Condition = {
            StringEquals = {
              "cloudwatch:namespace" = "bedrock-agentcore"
            }
          }
        },
        # Model invocation is opt-in. Prefer model-scoped statements through
        # additional_iam_statements over the wildcard convenience switch.
      ],
      var.allow_bedrock_invoke_all ? [
        {
          Sid    = "BedrockModelInvocation"
          Effect = "Allow"
          Action = [
            "bedrock:InvokeModel",
            "bedrock:InvokeModelWithResponseStream",
          ]
          Resource = "*"
        },
      ] : [],
      [
        {
          Sid    = "WorkloadAccessTokens"
          Effect = "Allow"
          Action = concat(
            [
              "bedrock-agentcore:GetWorkloadAccessToken",
              "bedrock-agentcore:GetWorkloadAccessTokenForJWT",
            ],
            var.allow_workload_access_token_for_user_id ? ["bedrock-agentcore:GetWorkloadAccessTokenForUserId"] : [],
          )
          Resource = local.workload_identity_resource_arns
        },
      ],
      var.allow_workload_access_token_for_user_id ? [] : [
        {
          Sid      = "DenyWorkloadAccessTokenForUserId"
          Effect   = "Deny"
          Action   = ["bedrock-agentcore:GetWorkloadAccessTokenForUserId"]
          Resource = local.workload_identity_resource_arns
        },
      ],
      var.runtime_memory_access_enabled ? [{
        Sid      = "AgentCoreMemoryRead"
        Effect   = "Allow"
        Action   = ["bedrock-agentcore:RetrieveMemoryRecords"]
        Resource = module.memory[0].memory_arn
      }] : [],
      var.runtime_browser_access_enabled ? [{
        Sid    = "AgentCoreBrowserSessions"
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:StartBrowserSession",
          "bedrock-agentcore:GetBrowserSession",
          "bedrock-agentcore:StopBrowserSession",
          "bedrock-agentcore:ConnectBrowserAutomationStream",
        ]
        Resource = module.browser[0].browser_arn
      }] : [],
      # Caller-supplied statements merged last so they can override defaults.
      var.additional_iam_statements,
    )
  })
}

# Runtime access to the custom Code Interpreter. This policy is separate from
# the baseline execution policy so it can target the generated custom ARN
# without creating a dependency cycle during Code Interpreter creation.
resource "aws_iam_role_policy" "code_interpreter_invoke" {
  count = var.create_execution_role && var.create_runtime && var.create_code_interpreter ? 1 : 0

  name = "${var.name}-code-interpreter-invoke"
  role = aws_iam_role.agent_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "CodeInterpreterSessions"
      Effect = "Allow"
      Action = [
        "bedrock-agentcore:GetCodeInterpreterSession",
        "bedrock-agentcore:InvokeCodeInterpreter",
        "bedrock-agentcore:ListCodeInterpreterSessions",
        "bedrock-agentcore:StartCodeInterpreterSession",
        "bedrock-agentcore:StopCodeInterpreterSession",
      ]
      Resource = module.code_interpreter[0].code_interpreter_arn
    }]
  })
}
