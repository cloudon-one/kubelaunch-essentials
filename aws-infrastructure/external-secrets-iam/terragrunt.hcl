include "root" {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

locals {
  platform_vars = yamldecode(file(find_in_parent_folders("platform_vars.yaml", "k8s-platform-tools/platform_vars.yaml")))
}

inputs = {
  environment      = local.platform_vars.common.environment
  eks_cluster_name = local.platform_vars.common.eks_cluster_name
  tags             = local.platform_vars.common.common_tags
}
