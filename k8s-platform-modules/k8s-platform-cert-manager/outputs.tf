output "release_name" {
  description = "The name of the Helm release"
  value       = helm_release.cert_manager.name
}

output "namespace" {
  description = "The namespace where cert-manager is installed"
  value       = helm_release.cert_manager.namespace
}

output "cluster_issuer_name" {
  description = "The name of the created ClusterIssuer"
  value       = var.create_cluster_issuer ? kubernetes_manifest.cluster_issuer[0].manifest.metadata.name : ""
}

output "aws_iam_role_arn" {
  description = "ARN of the created AWS IAM role"
  value       = try(aws_iam_role.cert_manager[0].arn, "")
}
