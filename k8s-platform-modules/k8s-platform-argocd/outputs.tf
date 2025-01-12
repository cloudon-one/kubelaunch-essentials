# outputs.tf

output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_service" {
  description = "Name of the ArgoCD server service"
  value       = "${helm_release.argocd.name}-server"
}

output "iam_role_arn" {
  description = "ARN of the IAM role created for ArgoCD"
  value       = aws_iam_role.argocd.arn
}

output "monitoring_enabled" {
  description = "Whether monitoring is enabled for ArgoCD"
  value       = var.enable_monitoring
}

output "prometheus_rules" {
  description = "Name of the PrometheusRules resource"
  value       = try(var.enable_monitoring ? kubernetes_manifest.argocd_prometheusrule[0].manifest.metadata.name : null, null)
}

output "grafana_dashboard" {
  description = "Name of the Grafana dashboard ConfigMap"
  value       = try(var.enable_monitoring ? kubernetes_config_map.argocd_dashboard[0].metadata[0].name : null, null)
}

output "configured_repositories" {
  description = "List of configured repository names"
  value       = [
    for repo in var.repositories : repo.name
    if lookup(kubernetes_secret.repo_credentials, repo.name, null) != null
  ]
  sensitive = true
}

output "repository_secrets" {
  description = "Map of repository names to their secret names"
  value = {
    for name, secret in kubernetes_secret.repo_credentials : name => secret.metadata[0].name
  }
  sensitive = true
}

output "github_app_configs" {
  description = "List of configured GitHub App IDs"
  value       = [
    for app in var.github_apps : app.id
  ]
}

output "certificate_configs" {
  description = "List of configured repository certificate server names"
  value       = [
    for cert in var.repositories_cert : cert.server_name
  ]
}