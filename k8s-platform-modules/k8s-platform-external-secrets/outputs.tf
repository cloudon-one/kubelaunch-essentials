output "release_name" {
  description = "The name of the Helm release"
  value       = helm_release.external_secrets.name
}

output "namespace" {
  description = "The namespace where external-secrets is installed"
  value       = helm_release.external_secrets.namespace
}

output "aws_iam_role_arn" {
  description = "ARN of the created AWS IAM role"
  value       = try(aws_iam_role.external_secrets[0].arn, "")
}

output "aws_iam_role_policies" {
  description = "Map of attached IAM role policies"
  value = {
    kms             = try(aws_iam_role_policy.kms[0].name, "")
    secrets_manager = try(aws_iam_role_policy.secrets_manager[0].name, "")
    parameter_store = try(aws_iam_role_policy.parameter_store[0].name, "")
    sts             = try(aws_iam_role_policy.sts[0].name, "")
  }
}