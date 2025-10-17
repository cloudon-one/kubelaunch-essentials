include "common" {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = "git::https://git@github.com/cloudon-one/k8s-platform-modules.git//k8s-platform-compliance-scanner?ref=dev"
}

locals {
  platform_vars = yamldecode(file(find_in_parent_folders("platform_vars.yaml")))
  tool          = basename(get_terragrunt_dir())
}

inputs = merge(
  local.platform_vars.Platform.Observability[local.tool].inputs,
  {
    environment         = local.platform_vars.common.environment
    eks_cluster_name    = local.platform_vars.common.eks_cluster_name
    aws_region          = local.platform_vars.common.aws_region
    aws_account_id      = local.platform_vars.common.aws_account_id
    common_tags         = local.platform_vars.common.common_tags
  }
)
