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
  environment     = local.platform_vars.common.environment
  secrets_to_rotate = [
    "${local.platform_vars.common.environment}/argocd/admin-password",
    "${local.platform_vars.common.environment}/kong/database-password",
    "${local.platform_vars.common.environment}/atlantis/github-token",
    "${local.platform_vars.common.environment}/atlantis/gitlab-token"
  ]
  rotation_schedule = "cron(0 2 1 * ? *)"  # Monthly on 1st at 2 AM UTC
  notification_emails = ["platform-alerts@cloudon.work"]
  tags = local.platform_vars.common.common_tags
}
