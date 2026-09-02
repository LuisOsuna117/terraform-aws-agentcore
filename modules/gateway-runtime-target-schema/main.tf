locals {
  # CloudFormation stack names must start with a letter. The Gateway hash
  # keeps the name unique without depending on the identifier's length.
  stack_name = "agentcore-${substr(var.name, 0, 50)}-${substr(sha256(var.gateway_identifier), 0, 12)}-runtime-schema"

  schema_source = merge(
    var.schema.inline_payload == null ? {} : {
      InlinePayload = var.schema.inline_payload.payload
    },
    var.schema.s3 == null ? {} : {
      S3 = merge(
        { Uri = var.schema.s3.uri },
        var.schema.s3.bucket_owner_account_id == null ? {} : {
          BucketOwnerAccountId = var.schema.s3.bucket_owner_account_id
        },
      )
    },
  )

  credential = var.credential_provider_configuration
  credential_provider_configuration = local.credential == null ? null : merge(
    {
      CredentialProviderType = (
        try(local.credential.api_key, null) != null ? "API_KEY" :
        try(local.credential.caller_iam_credentials, null) != null ? "CALLER_IAM_CREDENTIALS" :
        try(local.credential.gateway_iam_role, null) != null ? "GATEWAY_IAM_ROLE" :
        try(local.credential.jwt_passthrough, false) ? "JWT_PASSTHROUGH" :
        "OAUTH"
      )
    },
    try(local.credential.api_key, null) == null ? {} : {
      CredentialProvider = {
        ApiKeyCredentialProvider = merge(
          { ProviderArn = local.credential.api_key.provider_arn },
          local.credential.api_key.credential_location == null ? {} : { CredentialLocation = local.credential.api_key.credential_location },
          local.credential.api_key.credential_parameter_name == null ? {} : { CredentialParameterName = local.credential.api_key.credential_parameter_name },
          local.credential.api_key.credential_prefix == null ? {} : { CredentialPrefix = local.credential.api_key.credential_prefix },
        )
      }
    },
    try(local.credential.caller_iam_credentials, null) == null ? {} : {
      CredentialProvider = {
        IamCredentialProvider = merge(
          { Service = local.credential.caller_iam_credentials.service },
          local.credential.caller_iam_credentials.region == null ? {} : { Region = local.credential.caller_iam_credentials.region },
        )
      }
    },
    try(local.credential.oauth, null) == null ? {} : {
      CredentialProvider = {
        OauthCredentialProvider = merge(
          {
            ProviderArn = local.credential.oauth.provider_arn
            Scopes      = sort(tolist(local.credential.oauth.scopes))
          },
          local.credential.oauth.grant_type == null ? {} : { GrantType = local.credential.oauth.grant_type },
          local.credential.oauth.default_return_url == null ? {} : { DefaultReturnUrl = local.credential.oauth.default_return_url },
          length(local.credential.oauth.custom_parameters) == 0 ? {} : { CustomParameters = local.credential.oauth.custom_parameters },
        )
      }
    },
  )

  metadata_configuration = var.metadata_configuration == null ? {} : merge(
    length(var.metadata_configuration.allowed_query_parameters) == 0 ? {} : {
      AllowedQueryParameters = sort(tolist(var.metadata_configuration.allowed_query_parameters))
    },
    length(var.metadata_configuration.allowed_request_headers) == 0 ? {} : {
      AllowedRequestHeaders = sort(tolist(var.metadata_configuration.allowed_request_headers))
    },
    length(var.metadata_configuration.allowed_response_headers) == 0 ? {} : {
      AllowedResponseHeaders = sort(tolist(var.metadata_configuration.allowed_response_headers))
    },
  )

  private_endpoint = var.private_endpoint == null ? null : merge(
    try(var.private_endpoint.managed_vpc_resource, null) == null ? {} : {
      ManagedVpcResource = merge(
        {
          VpcIdentifier         = var.private_endpoint.managed_vpc_resource.vpc_identifier
          SubnetIds             = sort(tolist(var.private_endpoint.managed_vpc_resource.subnet_ids))
          EndpointIpAddressType = var.private_endpoint.managed_vpc_resource.endpoint_ip_address_type
          SecurityGroupIds      = sort(tolist(var.private_endpoint.managed_vpc_resource.security_group_ids))
          Tags                  = var.private_endpoint.managed_vpc_resource.tags
        },
        var.private_endpoint.managed_vpc_resource.routing_domain == null ? {} : {
          RoutingDomain = var.private_endpoint.managed_vpc_resource.routing_domain
        },
      )
    },
    try(var.private_endpoint.self_managed_lattice_resource, null) == null ? {} : {
      SelfManagedLatticeResource = {
        ResourceConfigurationIdentifier = var.private_endpoint.self_managed_lattice_resource.resource_configuration_identifier
      }
    },
  )

  target_properties = merge(
    {
      GatewayIdentifier = var.gateway_identifier
      Name              = var.name
      TargetConfiguration = {
        Http = {
          AgentcoreRuntime = {
            Arn       = var.runtime_arn
            Qualifier = var.qualifier
            Schema    = { Source = local.schema_source }
          }
        }
      }
    },
    var.description == null ? {} : { Description = var.description },
    local.credential_provider_configuration == null ? {} : {
      CredentialProviderConfigurations = [local.credential_provider_configuration]
    },
    length(local.metadata_configuration) == 0 ? {} : {
      MetadataConfiguration = local.metadata_configuration
    },
    local.private_endpoint == null ? {} : { PrivateEndpoint = local.private_endpoint },
  )

  template = {
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "AgentCore HTTP Runtime target with an API schema."
    Resources = {
      RuntimeTarget = {
        Type       = "AWS::BedrockAgentCore::GatewayTarget"
        Properties = local.target_properties
      }
    }
    Outputs = {
      TargetId = {
        Value = { "Fn::GetAtt" = ["RuntimeTarget", "TargetId"] }
      }
      GatewayArn = {
        Value = { "Fn::GetAtt" = ["RuntimeTarget", "GatewayArn"] }
      }
    }
  }
}

resource "aws_cloudformation_stack" "this" {
  name          = local.stack_name
  region        = var.region
  template_body = jsonencode(local.template)
  tags          = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
