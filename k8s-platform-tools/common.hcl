terraform {
  extra_arguments "common" {
    commands = get_terraform_commands_that_need_vars()
  }
  extra_arguments "non-interactive" {
    commands = [
      "apply"

    ]
    arguments = [
      "-compact-warnings", 
    ]
  }
}

locals {
  platform_vars     = yamldecode(file(("platform_vars.yaml")))
  eks_cluster_name  = local.platform_vars.common.eks_cluster_name
  environment       = get_env("ENV", "dev")
  aws_region        = local.platform_vars.common.aws_region
  aws_account_id    = get_aws_account_id()  # Dynamic lookup
  tags              = local.platform_vars.common.common_tags
}


remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "${local.platform_vars.common.owner}-${local.platform_vars.common.provider}-admin-${local.platform_vars.common.statebucketsuffix}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.platform_vars.common.aws_region
    encrypt        = true

    # SECURITY: DynamoDB state locking
    dynamodb_table = "${local.platform_vars.common.owner}-terraform-state-locks"

    # SECURITY: KMS encryption
    kms_key_id     = "alias/terraform-state"

    # Security best practices
    skip_credentials_validation = false
    skip_metadata_api_check     = false
  }
}
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.platform_vars.common.aws_region}"

  default_tags {
    tags = ${jsonencode(local.tags)}
  }
}
EOF
}