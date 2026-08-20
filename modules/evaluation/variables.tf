variable "name" {
  description = "Base name for Evaluator and online evaluation resources."
  type        = string
}

variable "evaluators" {
  description = "AgentCore Evaluators. Configure exactly one of code_based or llm_judge."
  type = map(object({
    name        = optional(string)
    level       = string
    description = optional(string)
    kms_key_arn = optional(string)
    region      = optional(string)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
    code_based = optional(object({
      lambda_arn      = string
      timeout_seconds = optional(number, 60)
    }))
    llm_judge = optional(object({
      instructions                    = string
      model_id                        = string
      max_tokens                      = optional(number, 2048)
      temperature                     = optional(number, 0)
      top_p                           = optional(number, 1)
      additional_model_request_fields = optional(string)
      stop_sequences                  = optional(list(string), [])
      categories = optional(list(object({
        label      = string
        definition = string
      })), [])
      numerical = optional(list(object({
        label      = string
        definition = string
        value      = number
      })), [])
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for evaluator in values(var.evaluators) : (evaluator.code_based != null) != (evaluator.llm_judge != null)
    ])
    error_message = "Each evaluator must configure exactly one of code_based or llm_judge."
  }

  validation {
    condition = alltrue([
      for evaluator in values(var.evaluators) : evaluator.llm_judge == null ? true : (
        (length(evaluator.llm_judge.categories) > 0) != (length(evaluator.llm_judge.numerical) > 0)
      )
    ])
    error_message = "Each llm_judge must configure exactly one non-empty categorical or numerical rating scale."
  }
}

variable "online_evaluations" {
  description = "Online evaluation configs sourcing AgentCore telemetry from CloudWatch Logs."
  type = map(object({
    name                    = optional(string)
    description             = optional(string)
    execution_role_arn      = string
    evaluator_keys          = optional(set(string), [])
    evaluator_ids           = optional(set(string), [])
    log_group_names         = set(string)
    service_names           = set(string)
    sampling_percentage     = number
    session_timeout_minutes = number
    enable_on_create        = optional(bool, true)
    region                  = optional(string)
    filters = optional(list(object({
      key      = string
      operator = string
      value = object({
        boolean_value = optional(bool)
        double_value  = optional(number)
        string_value  = optional(string)
      })
    })), [])
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for config in values(var.online_evaluations) : (
        length(config.evaluator_keys) + length(config.evaluator_ids) > 0 &&
        config.sampling_percentage >= 0.01 && config.sampling_percentage <= 100 &&
        config.session_timeout_minutes >= 1 && config.session_timeout_minutes <= 60 &&
        floor(config.session_timeout_minutes) == config.session_timeout_minutes
      )
    ])
    error_message = "Each online evaluation requires at least one evaluator, sampling_percentage between 0.01 and 100, and an integer session_timeout_minutes between 1 and 60."
  }

  validation {
    condition = alltrue(flatten([
      for config in values(var.online_evaluations) : [
        for filter in config.filters : (
          contains(["Equals", "NotEquals", "GreaterThan", "LessThan", "GreaterThanOrEqual", "LessThanOrEqual", "Contains", "NotContains"], filter.operator) &&
          length(compact([
            filter.value.boolean_value == null ? "" : "boolean_value",
            filter.value.double_value == null ? "" : "double_value",
            filter.value.string_value == null ? "" : "string_value",
          ])) == 1
        )
      ]
    ]))
    error_message = "Each online evaluation filter must use a supported operator and exactly one value type."
  }
}

variable "tags" {
  description = "Tags to apply to evaluation resources."
  type        = map(string)
  default     = {}
}
