locals {
  create      = var.create
  common_tags = var.tags
}

module "image_build" {
  for_each = local.create ? var.image_builds : {}
  source   = "./modules/build"

  name                = coalesce(each.value.name, "${var.name}-${each.key}")
  common_tags         = local.common_tags
  ecr_repository_name = coalesce(each.value.ecr_repository_name, replace(lower(coalesce(each.value.name, "${var.name}-${each.key}")), "_", "-"))

  ecr_image_tag_mutability = each.value.ecr_image_tag_mutability
  ecr_scan_on_push         = each.value.ecr_scan_on_push
  ecr_lifecycle_keep_count = each.value.ecr_lifecycle_keep_count
  ecr_force_delete         = each.value.ecr_force_delete
  ecr_pull_principals      = each.value.ecr_pull_principals

  agent_source_dir            = each.value.source_dir
  source_bucket_force_destroy = each.value.source_bucket_force_destroy

  image_tag                   = each.value.image_tag
  codebuild_compute_type      = each.value.codebuild_compute_type
  codebuild_environment_image = each.value.codebuild_environment_image
  codebuild_environment_type  = each.value.codebuild_environment_type
  codebuild_build_timeout     = each.value.codebuild_build_timeout
  trigger_build_on_apply      = each.value.trigger_build_on_apply
}
