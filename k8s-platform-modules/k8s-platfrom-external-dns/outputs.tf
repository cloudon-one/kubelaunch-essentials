output "release_name" {
  description = "The name of the Helm release"
  value       = helm_release.external_dns.name
}

output "namespace" {
  description = "The namespace where external-dns is installed"
  value       = helm_release.external_dns.namespace
}

output "aws_iam_role_arn" {
  description = "ARN of the created AWS IAM role"
  value       = try(aws_iam_role.external_dns[0].arn, "")
}

output "service_account_name" {
  description = "Name of the created Kubernetes service account"
  value       = var.service_account_name
}