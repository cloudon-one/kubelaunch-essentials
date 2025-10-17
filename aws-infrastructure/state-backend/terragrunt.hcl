include "root" {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

locals {
  platform_vars = yamldecode(file(find_in_parent_folders("platform_vars.yaml", "k8s-platform-tools/platform_vars.yaml")))
}

# Skip remote state for this module since it creates the state backend infrastructure
skip = true

inputs = {
  owner             = local.platform_vars.common.owner
  state_bucket_name = "${local.platform_vars.common.owner}-${local.platform_vars.common.provider}-admin-${local.platform_vars.common.statebucketsuffix}"
  tags              = local.platform_vars.common.common_tags
}
