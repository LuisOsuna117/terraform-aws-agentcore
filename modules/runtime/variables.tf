variable "runtime_name" {
  description = "Resolved name for the AgentCore runtime (hyphens already converted to underscores)."
  type        = string
}

variable "description" {
  description = "Human-readable description of the runtime."
  type        = string
  default     = "Managed by terraform-aws-agentcore."
}

variable "execution_role_arn" {
  description = "ARN of the IAM execution role the runtime assumes."
  type        = string
}

variable "image_uri" {
  description = "ECR container image URI (including a tag or digest). Exactly one of image_uri or code_configuration must be set."
  type        = string
  default     = null

  validation {
    condition     = var.image_uri == null || can(regex("^[0-9]{12}\\.dkr\\.ecr(?:-fips)?\\.[a-z0-9-]+\\.amazonaws\\.com(?:\\.cn)?/[a-z0-9._/-]+(?::[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}|@sha256:[a-f0-9]{64})$", var.image_uri))
    error_message = "image_uri must be a tagged or digest-pinned Amazon ECR image URI."
  }
}

variable "code_configuration" {
  description = "Optional direct code artifact stored in S3. Exactly one of image_uri or code_configuration must be set."
  type = object({
    entry_point = list(string)
    runtime     = string
    s3 = object({
      bucket     = string
      prefix     = string
      version_id = optional(string)
    })
  })
  default = null
}

variable "filesystems" {
  description = "Opt-in Runtime filesystem mounts. Each entry configures exactly one session, S3 Files, or EFS mount."
  type = list(object({
    session_storage = optional(object({
      mount_path = string
    }))
    s3_files_access_point = optional(object({
      access_point_arn = string
      mount_path       = string
    }))
    efs_access_point = optional(object({
      access_point_arn = string
      mount_path       = string
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for filesystem in var.filesystems : length(compact([
        filesystem.session_storage == null ? "" : "session_storage",
        filesystem.s3_files_access_point == null ? "" : "s3_files_access_point",
        filesystem.efs_access_point == null ? "" : "efs_access_point",
      ])) == 1
    ])
    error_message = "Each filesystems entry must configure exactly one mount type."
  }
}

# ==============================================================================
# Network
# ==============================================================================

variable "network_mode" {
  description = "Network mode for the AgentCore runtime. Valid values: PUBLIC, VPC."
  type        = string
  default     = "PUBLIC"

  validation {
    condition     = contains(["PUBLIC", "VPC"], var.network_mode)
    error_message = "network_mode must be either \"PUBLIC\" or \"VPC\"."
  }
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for VPC mode. Required when network_mode = \"VPC\"."
  type        = list(string)
  default     = []
}

variable "vpc_subnet_ids" {
  description = "Subnet IDs for VPC mode. Required when network_mode = \"VPC\"."
  type        = list(string)
  default     = []
}

# ==============================================================================
# Authorizer
# ==============================================================================

variable "authorizer_configuration" {
  description = "Optional CUSTOM_JWT authorizer with scopes, workload restrictions, custom claims, and private issuer connectivity."
  type = object({
    discovery_url            = string
    allowed_audience         = optional(set(string), [])
    allowed_clients          = optional(set(string), [])
    allowed_scopes           = optional(set(string), [])
    workload_identities      = optional(list(string), [])
    hosting_environment_arns = optional(list(string), [])
    custom_claims = optional(set(object({
      inbound_token_claim_name       = string
      inbound_token_claim_value_type = string
      claim_match_operator           = string
      match_value_string             = optional(string)
      match_value_string_list        = optional(set(string))
    })), [])
    private_endpoint = optional(object({
      managed_vpc_resource = optional(object({
        endpoint_ip_address_type = string
        subnet_ids               = set(string)
        vpc_identifier           = string
        routing_domain           = optional(string)
        security_group_ids       = optional(set(string), [])
        tags                     = optional(map(string), {})
      }))
      self_managed_lattice_resource = optional(object({
        resource_configuration_identifier = string
      }))
    }))
    private_endpoint_overrides = optional(list(object({
      domain = string
      private_endpoint = object({
        managed_vpc_resource = optional(object({
          endpoint_ip_address_type = string
          subnet_ids               = set(string)
          vpc_identifier           = string
          routing_domain           = optional(string)
          security_group_ids       = optional(set(string), [])
          tags                     = optional(map(string), {})
        }))
        self_managed_lattice_resource = optional(object({
          resource_configuration_identifier = string
        }))
      })
    })), [])
  })
  default = null

  validation {
    condition = var.authorizer_configuration == null ? true : alltrue([
      for claim in var.authorizer_configuration.custom_claims : (
        contains(["STRING", "STRING_ARRAY"], claim.inbound_token_claim_value_type) &&
        contains(["EQUALS", "CONTAINS", "CONTAINS_ANY"], claim.claim_match_operator) &&
        ((claim.match_value_string != null) != (claim.match_value_string_list != null)) &&
        (claim.claim_match_operator != "EQUALS" || claim.inbound_token_claim_value_type == "STRING") &&
        (!contains(["CONTAINS", "CONTAINS_ANY"], claim.claim_match_operator) || claim.inbound_token_claim_value_type == "STRING_ARRAY") &&
        (claim.claim_match_operator != "CONTAINS_ANY" || claim.match_value_string_list != null) &&
        (claim.claim_match_operator == "CONTAINS_ANY" || claim.match_value_string != null)
      )
    ])
    error_message = "Each JWT custom claim must use a compatible value type, operator, and exactly one match value shape."
  }

  validation {
    condition = var.authorizer_configuration == null ? true : (
      var.authorizer_configuration.private_endpoint == null ? true : (
        (var.authorizer_configuration.private_endpoint.managed_vpc_resource != null) !=
        (var.authorizer_configuration.private_endpoint.self_managed_lattice_resource != null)
      )
    )
    error_message = "authorizer_configuration.private_endpoint must configure exactly one managed or self-managed VPC resource."
  }

  validation {
    condition = var.authorizer_configuration == null ? true : alltrue([
      for override in var.authorizer_configuration.private_endpoint_overrides : (
        (override.private_endpoint.managed_vpc_resource != null) !=
        (override.private_endpoint.self_managed_lattice_resource != null)
      )
    ])
    error_message = "Each JWT private endpoint override must configure exactly one managed or self-managed VPC resource."
  }

  validation {
    condition = var.authorizer_configuration == null || (
      length(var.authorizer_configuration.workload_identities) <= 10 &&
      alltrue([
        for identity in var.authorizer_configuration.workload_identities :
        can(regex("^[A-Za-z0-9_.-]{3,255}$", identity))
      ])
    )
    error_message = "authorizer_configuration.workload_identities must contain at most 10 workload identity names, not ARNs."
  }
}

# ==============================================================================
# Lifecycle
# ==============================================================================

variable "idle_runtime_session_timeout" {
  description = "Idle session timeout in seconds. When null, the service default applies."
  type        = number
  default     = null
}

variable "max_lifetime" {
  description = "Maximum instance lifetime in seconds. When null, the service default applies."
  type        = number
  default     = null
}

# ==============================================================================
# Protocol
# ==============================================================================

variable "server_protocol" {
  description = "Server protocol for the runtime. Valid values: HTTP, MCP, A2A, AGUI. When null, the service default (HTTP) applies."
  type        = string
  default     = null

  validation {
    condition     = var.server_protocol == null ? true : contains(["HTTP", "MCP", "A2A", "AGUI"], var.server_protocol)
    error_message = "server_protocol must be one of: HTTP, MCP, A2A, AGUI."
  }
}

variable "request_header_allowlist" {
  description = "List of HTTP request headers to pass through to the runtime. When empty, no additional headers are forwarded."
  type        = list(string)
  default     = []
}

# ==============================================================================
# Environment
# ==============================================================================

variable "environment_variables" {
  description = "Environment variables injected into the runtime process."
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS Region in which to manage the Runtime. Defaults to the provider Region."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the Runtime."
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Optional create, update, and delete timeouts for the Runtime."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
