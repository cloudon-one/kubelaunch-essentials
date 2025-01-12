output "namespace" {
  description = "The namespace where Vault is deployed"
  value       = local.namespace
}

output "name" {
  description = "Name of the Vault deployment"
  value       = helm_release.vault.name
}

output "release_name" {
  description = "The name of the Helm release"
  value       = helm_release.vault.name
}

output "service_name" {
  description = "The name of the Vault service"
  value       = "${helm_release.vault.name}-vault"
}

output "service_account_name" {
  description = "Name of the Vault service account"
  value       = kubernetes_service_account.vault.metadata[0].name
}