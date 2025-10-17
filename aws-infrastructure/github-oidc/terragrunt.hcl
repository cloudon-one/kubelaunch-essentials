include "root" {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

locals {
  platform_vars = yamldecode(file(find_in_parent_folders("platform_vars.yaml", "k8s-platform-tools/platform_vars.yaml")))
  aws_region    = local.platform_vars.common.aws_region
  owner         = local.platform_vars.common.owner
}

dependency "state_backend" {
  config_path = "../state-backend"

  mock_outputs = {
    state_bucket_arn    = "arn:aws:s3:::mock-bucket"
    dynamodb_table_arn  = "arn:aws:dynamodb:us-east-2:123456789012:table/mock-table"
  }
}

inputs = {
  github_org     = "cloudon-one"
  allowed_repositories = [
    "kubelaunch-essentials",
    "k8s-platform-modules"
  ]
  state_bucket_arns = [dependency.state_backend.outputs.state_bucket_arn]
  dynamodb_table_arn = dependency.state_backend.outputs.dynamodb_table_arn
  tags = local.platform_vars.common.common_tags
}
