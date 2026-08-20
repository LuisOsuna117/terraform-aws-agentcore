variable "create" {
  description = "Controls whether this module creates resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name used as the default prefix for module-managed resources."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "tags" {
  description = "Tags applied to every taggable resource."
  type        = map(string)
  default     = {}
}

variable "runtimes" {
  description = "AgentCore Runtimes. Authentication is explicit per runtime; CUSTOM_JWT and AWS_IAM cannot be combined."
  type = map(object({
    name                            = optional(string)
    role_arn                        = string
    image_uri                       = string
    authentication                  = string
    description                     = optional(string)
    environment_variables           = optional(map(string), {})
    gateway_url_environment         = optional(map(string), {})
    memory_id_environment           = optional(map(string), {})
    browser_id_environment          = optional(map(string), {})
    browser_profile_id_environment  = optional(map(string), {})
    code_interpreter_id_environment = optional(map(string), {})
    network_mode                    = optional(string, "PUBLIC")
    security_groups                 = optional(set(string), [])
    subnets                         = optional(set(string), [])
    server_protocol                 = optional(string, "HTTP")
    request_headers                 = optional(set(string), [])
    idle_timeout_seconds            = optional(number, 900)
    max_lifetime_seconds            = optional(number, 28800)
    jwt = optional(object({
      discovery_url               = string
      allowed_audience            = optional(set(string), [])
      allowed_clients             = optional(set(string), [])
      allowed_scopes              = optional(set(string), [])
      allowed_gateway_arn         = optional(string)
      allowed_gateway_key         = optional(string)
      allowed_workload_identities = optional(list(string), [])
      claims = optional(list(object({
        name         = string
        value_type   = string
        operator     = string
        string_value = optional(string)
        string_list  = optional(set(string), [])
      })), [])
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for runtime in values(var.runtimes) :
      contains(["AWS_IAM", "CUSTOM_JWT"], runtime.authentication) &&
      (runtime.authentication == "CUSTOM_JWT") == (runtime.jwt != null) &&
      (runtime.jwt == null || !(runtime.jwt.allowed_gateway_arn != null && runtime.jwt.allowed_gateway_key != null)) &&
      (runtime.network_mode == "PUBLIC" || (runtime.network_mode == "VPC" && length(runtime.security_groups) > 0 && length(runtime.subnets) > 0))
    ])
    error_message = "Each runtime must use exactly AWS_IAM or CUSTOM_JWT; JWT config is required only for CUSTOM_JWT, and VPC mode requires subnets and security groups."
  }
}

variable "runtime_endpoints" {
  description = "Named immutable Runtime endpoints."
  type = map(object({
    runtime_key     = string
    name            = optional(string)
    description     = optional(string)
    runtime_version = optional(string)
  }))
  default = {}
}

variable "workload_identities" {
  description = "AgentCore workload identities for outbound authentication."
  type = map(object({
    name                      = optional(string)
    allowed_oauth_return_urls = optional(set(string), [])
  }))
  default = {}
}

variable "api_key_credential_providers" {
  description = "AgentCore Identity API-key providers. The key is write-only and is never returned by this module."
  type = map(object({
    name               = optional(string)
    api_key_write_only = string
    secret_version     = number
  }))
  default = {}
}

variable "oauth2_credential_providers" {
  description = "Custom AgentCore Identity OAuth2 providers. Client credentials are write-only and are never returned."
  type = map(object({
    name                     = optional(string)
    client_id_write_only     = string
    client_secret_write_only = string
    credentials_version      = number
    discovery_url            = optional(string)
    issuer                   = optional(string)
    authorization_endpoint   = optional(string)
    token_endpoint           = optional(string)
    response_types           = optional(set(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for provider in values(var.oauth2_credential_providers) :
      provider.discovery_url != null || (
        provider.issuer != null &&
        provider.authorization_endpoint != null &&
        provider.token_endpoint != null
      )
    ])
    error_message = "Each OAuth2 provider requires discovery_url or explicit issuer, authorization endpoint, and token endpoint."
  }
}

variable "policy_engines" {
  description = "AgentCore Cedar policy engines."
  type = map(object({
    name               = optional(string)
    description        = optional(string)
    encryption_key_arn = optional(string)
  }))
  default = {}
}

variable "policies" {
  description = "Cedar policies, normally generated tool-by-tool from the caller's security catalog."
  type = map(object({
    engine_key = string
    name       = optional(string)
    statement  = optional(string)
    scoped = optional(object({
      gateway_key    = string
      principal_type = string
      action_id      = string
      condition      = optional(string)
    }))
    description     = optional(string)
    validation_mode = optional(string, "FAIL_ON_ANY_FINDINGS")
  }))
  default = {}

  validation {
    condition = alltrue([
      for policy in values(var.policies) : (policy.statement != null) != (policy.scoped != null)
    ])
    error_message = "Each policy must provide exactly one of statement or scoped."
  }
}

variable "resource_policies" {
  description = "Resource policies for runtimes, gateways, and other AgentCore resources."
  type = map(object({
    resource_arn  = optional(string)
    resource_type = optional(string)
    resource_key  = optional(string)
    policy        = optional(string)
    principals    = optional(set(string), [])
    actions       = optional(set(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for binding in values(var.resource_policies) :
      (binding.resource_arn != null) != (binding.resource_type != null && binding.resource_key != null) &&
      (binding.policy != null) != (length(binding.principals) > 0 && length(binding.actions) > 0) &&
      !contains(binding.principals, "*") && !contains(binding.actions, "*") &&
      (binding.resource_type == null || contains(["RUNTIME", "GATEWAY", "MEMORY"], binding.resource_type))
    ])
    error_message = "Each resource policy must select exactly one external ARN or one module-managed RUNTIME, GATEWAY, or MEMORY key."
  }
}

variable "runtime_role_permissions" {
  description = "Least-privilege inline policies attached to caller-owned Runtime roles, with module resource references resolved without cycles."
  type = map(object({
    runtime_key = string
    statements = list(object({
      sid                    = string
      actions                = set(string)
      resources              = optional(set(string), [])
      gateway_keys           = optional(set(string), [])
      memory_keys            = optional(set(string), [])
      code_interpreter_keys  = optional(set(string), [])
      browser_keys           = optional(set(string), [])
      gateway_parameter_keys = optional(set(string), [])
    }))
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for policy in values(var.runtime_role_permissions) : [
        for statement in policy.statements :
        length(statement.actions) > 0 && !contains(statement.actions, "*") && !contains(statement.resources, "*")
      ]
    ]))
    error_message = "Runtime role policies must declare concrete actions and cannot use wildcard actions or resources."
  }
}

variable "gateway_role_permissions" {
  description = "Least-privilege inline policies attached to caller-owned Gateway roles."
  type = map(object({
    gateway_key = string
    statements = list(object({
      sid                    = string
      actions                = set(string)
      resources              = optional(set(string), [])
      runtime_keys           = optional(set(string), [])
      api_key_provider_keys  = optional(set(string), [])
      oauth2_credential_keys = optional(set(string), [])
      workload_identity_keys = optional(set(string), [])
    }))
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for policy in values(var.gateway_role_permissions) : [
        for statement in policy.statements :
        length(statement.actions) > 0 && !contains(statement.actions, "*") && !contains(statement.resources, "*")
      ]
    ]))
    error_message = "Gateway role policies must declare concrete actions and cannot use wildcard actions or resources."
  }
}

variable "gateways" {
  description = "AgentCore Gateways. An attached policy engine always runs in ENFORCE mode."
  type = map(object({
    name              = optional(string)
    role_arn          = string
    authentication    = string
    description       = optional(string)
    kms_key_arn       = optional(string)
    exception_level   = optional(string)
    policy_engine_key = optional(string)
    protocol_type     = optional(string)
    jwt = optional(object({
      discovery_url               = string
      allowed_audience            = optional(set(string), [])
      allowed_clients             = optional(set(string), [])
      allowed_scopes              = optional(set(string), [])
      allowed_workload_identities = optional(list(string), [])
      claims = optional(list(object({
        name         = string
        value_type   = string
        operator     = string
        string_value = optional(string)
        string_list  = optional(set(string), [])
      })), [])
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for gateway in values(var.gateways) :
      contains(["AWS_IAM", "CUSTOM_JWT"], gateway.authentication) &&
      (gateway.authentication == "CUSTOM_JWT") == (gateway.jwt != null)
    ])
    error_message = "Each gateway must use exactly AWS_IAM or CUSTOM_JWT, with JWT config only for CUSTOM_JWT."
  }
}

variable "gateway_targets" {
  description = "AgentCore Runtime or MCP-server Gateway targets with one explicit outbound credential mode."
  type = map(object({
    gateway_key               = string
    name                      = optional(string)
    target_type               = string
    runtime_key               = optional(string)
    runtime_arn               = optional(string)
    qualifier                 = optional(string, "DEFAULT")
    mcp_endpoint              = optional(string)
    mcp_listing_mode          = optional(string)
    credential_mode           = string
    signing_service           = optional(string, "bedrock-agentcore")
    signing_region            = optional(string)
    credential_provider_key   = optional(string)
    credential_provider_arn   = optional(string)
    credential_location       = optional(string, "HEADER")
    credential_parameter_name = optional(string)
    credential_prefix         = optional(string)
    oauth_grant_type          = optional(string)
    oauth_scopes              = optional(set(string), [])
    oauth_default_return_url  = optional(string)
    oauth_custom_parameters   = optional(map(string), {})
    description               = optional(string)
    allowed_query_parameters  = optional(set(string), [])
    allowed_request_headers   = optional(set(string), [])
    allowed_response_headers  = optional(set(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for target in values(var.gateway_targets) :
      contains(["HTTP_RUNTIME", "MCP_SERVER"], target.target_type) &&
      contains(["JWT_PASSTHROUGH", "GATEWAY_IAM_ROLE", "CALLER_IAM_CREDENTIALS", "API_KEY", "OAUTH"], target.credential_mode) &&
      (
        target.target_type == "HTTP_RUNTIME"
        ? ((target.runtime_key != null) != (target.runtime_arn != null)) && target.mcp_endpoint == null
        : target.runtime_key == null && target.runtime_arn == null && target.mcp_endpoint != null
      ) &&
      (
        contains(["API_KEY", "OAUTH"], target.credential_mode)
        ? ((target.credential_provider_key != null) != (target.credential_provider_arn != null))
        : target.credential_provider_key == null && target.credential_provider_arn == null
      ) &&
      (target.credential_mode != "API_KEY" || target.credential_parameter_name != null) &&
      (target.credential_mode != "OAUTH" || (target.oauth_grant_type != null && length(target.oauth_scopes) > 0))
    ])
    error_message = "Each Gateway target must select one target type, one credential mode, and only the fields required by that combination."
  }
}

variable "gateway_rules" {
  description = "Path rules that route to a named target; optional IAM principals constrain workload routes."
  type = map(object({
    gateway_key    = string
    priority       = number
    paths          = list(string)
    target_name    = string
    description    = optional(string)
    iam_principals = optional(set(string), [])
  }))
  default = {}
}

variable "gateway_discovery_parameters" {
  description = "SSM parameters that publish generated Gateway URLs without creating Runtime/Gateway dependency cycles."
  type = map(object({
    gateway_key = string
    name        = string
    description = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for item in values(var.gateway_discovery_parameters) : startswith(item.name, "/")])
    error_message = "Gateway discovery parameter names must be absolute SSM paths."
  }
}

variable "memories" {
  description = "AgentCore Memory stores. Namespace content is never an authority source."
  type = map(object({
    name                      = optional(string)
    event_expiry_duration     = number
    description               = optional(string)
    encryption_key_arn        = optional(string)
    memory_execution_role_arn = optional(string)
    indexed_keys = optional(list(object({
      key  = string
      type = string
    })), [])
  }))
  default = {}
}

variable "memory_strategies" {
  description = "Memory strategies attached to a module-managed Memory."
  type = map(object({
    memory_key                = string
    name                      = optional(string)
    type                      = string
    description               = optional(string)
    namespaces                = optional(list(string), [])
    namespace_templates       = optional(list(string), [])
    memory_execution_role_arn = optional(string)
  }))
  default = {}
}

variable "browsers" {
  description = "AgentCore Browser sandboxes. VPC mode requires subnets and security groups."
  type = map(object({
    name               = optional(string)
    description        = optional(string)
    execution_role_arn = optional(string)
    network_mode       = optional(string, "PUBLIC")
    security_groups    = optional(set(string), [])
    subnets            = optional(set(string), [])
    browser_signing    = optional(bool, false)
  }))
  default = {}
}

variable "browser_profiles" {
  description = "Reusable Browser profiles."
  type = map(object({
    name        = optional(string)
    description = optional(string)
  }))
  default = {}
}

variable "code_interpreters" {
  description = "AgentCore Code Interpreter sandboxes. SANDBOX is the safe no-network default."
  type = map(object({
    name               = optional(string)
    description        = optional(string)
    execution_role_arn = optional(string)
    network_mode       = optional(string, "SANDBOX")
    security_groups    = optional(set(string), [])
    subnets            = optional(set(string), [])
  }))
  default = {}
}

variable "harnesses" {
  description = "Managed Harness configurations for non-production experimentation without effect tools."
  type = map(object({
    name                  = optional(string)
    execution_role_arn    = string
    image_uri             = string
    model_id              = string
    system_prompt         = string
    environment_variables = optional(map(string), {})
    network_mode          = optional(string, "PUBLIC")
    security_groups       = optional(set(string), [])
    subnets               = optional(set(string), [])
    require_s3_endpoint   = optional(bool, false)
    idle_timeout_seconds  = optional(number)
    max_lifetime_seconds  = optional(number)
    allowed_tools         = optional(set(string), [])
    max_iterations        = optional(number, 10)
    max_tokens            = optional(number, 8192)
    timeout_seconds       = optional(number, 900)
    temperature           = optional(number, 0)
    top_p                 = optional(number, 1)
  }))
  default = {}
}

variable "evaluators" {
  description = "AgentCore evaluators. Configure exactly one of code_based or llm_judge."
  type = map(object({
    name        = optional(string)
    level       = string
    description = optional(string)
    kms_key_arn = optional(string)
    code_based = optional(object({
      lambda_arn      = string
      timeout_seconds = optional(number, 60)
    }))
    llm_judge = optional(object({
      instructions = string
      model_id     = string
      max_tokens   = optional(number, 2048)
      temperature  = optional(number, 0)
      top_p        = optional(number, 1)
      categories = list(object({
        label      = string
        definition = string
      }))
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for evaluator in values(var.evaluators) :
      (evaluator.code_based != null) != (evaluator.llm_judge != null)
    ])
    error_message = "Each evaluator must configure exactly one of code_based or llm_judge."
  }
}

variable "online_evaluations" {
  description = "Online evaluation configs sourcing sanitized AgentCore telemetry from CloudWatch Logs."
  type = map(object({
    name                    = optional(string)
    execution_role_arn      = string
    evaluator_keys          = set(string)
    log_group_names         = set(string)
    service_names           = set(string)
    sampling_percentage     = number
    session_timeout_minutes = number
    enable_on_create        = optional(bool, true)
    description             = optional(string)
  }))
  default = {}
}

variable "registries" {
  description = "AWS Agent Registry Preview catalogs in the current agent-registry namespace, isolated behind CloudFormation until the AWS provider exposes a native resource."
  type = map(object({
    name               = optional(string)
    log_retention_days = optional(number, 365)
  }))
  default = {}

  validation {
    condition = alltrue([
      for registry in values(var.registries) : registry.log_retention_days >= 365
    ])
    error_message = "Registry lifecycle logs must be retained for at least 365 days."
  }
}

variable "observability" {
  description = "CloudWatch log groups used by AgentCore Observability, evaluations, and sanitized usage telemetry."
  type = map(object({
    log_group_name    = string
    retention_in_days = optional(number, 365)
    kms_key_arn       = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for config in values(var.observability) : config.retention_in_days >= 365])
    error_message = "AgentCore observability retention must be at least 365 days."
  }
}

variable "preview_stacks" {
  description = "Isolated CloudFormation stacks for AgentCore Preview resources absent from the AWS provider. Templates must reference secrets externally."
  type = map(object({
    name          = optional(string)
    template_body = string
    parameters    = optional(map(string), {})
    capabilities  = optional(set(string), [])
  }))
  default = {}
}
