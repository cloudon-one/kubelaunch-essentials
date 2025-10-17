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
  environment                  = local.platform_vars.common.environment
  failed_login_threshold       = 10
  policy_violation_threshold   = 50
  security_team_emails         = ["platform-alerts@cloudon.work", "security@cloudon.work"]
  slack_webhook_url            = ""  # Retrieved from AWS Secrets Manager at runtime
  tags                         = local.platform_vars.common.common_tags
}
