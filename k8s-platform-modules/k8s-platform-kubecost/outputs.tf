output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.kubecost.metadata[0].name
}

output "service_account_name" {
  description = "Service account name"
  value       = kubernetes_service_account.kubecost.metadata[0].name
}

output "role_arn" {
  description = "IAM role ARN"
  value       = var.create_iam_resources ? aws_iam_role.kubecost[0].arn : null
}

output "policy_arn" {
  description = "IAM policy ARN"
  value       = var.create_iam_resources ? aws_iam_policy.kubecost[0].arn : null
}