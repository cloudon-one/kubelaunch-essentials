include "common" {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = "git::https://git@github.com/cloudon-one/k8s-platform-modules.git//k8s-platform-loki-stack?ref=dev"
}

locals {
  platform_vars = yamldecode(file(find_in_parent_folders("platform_vars.yaml")))
  tool          = basename(get_terragrunt_dir())
}

  inputs = merge(
    local.platform_vars.Platform.Tools[local.tool].inputs,
    {
      cluster_name = local.platform_vars.common.eks_cluster_name  
      cluster_oidc_provider = local.platform_vars.common.cluster_oidc_provider
    }
  )