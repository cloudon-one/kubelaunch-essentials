output "namespace" {
  description = "The namespace where Atlantis is deployed"
  value       = local.namespace
}

output "service_account_name" {
  description = "The name of the service account"
  value       = kubernetes_service_account.atlantis.metadata[0].name
}

output "webhook_url" {
  description = "The webhook URL for Atlantis"
  value       = var.webhook_url
}