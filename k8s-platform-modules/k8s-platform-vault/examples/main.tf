module "vault" {
  source = "./k8s-platform-vault"  # Update with actual source

  name          = "vault"
  namespace     = "vault-system"
  replicas      = 3
  storage_class = "gp2"
  
  service_account_annotations = {
    "eks.amazonaws.com/role-arn" = "arn:aws:iam::123456789012:role/vault-role"
  }
  
  # Additional Helm values
  helm_values = {
    server = {
      resources = {
        requests = {
          memory = "256Mi"
          cpu    = "250m"
        }
        limits = {
          memory = "512Mi"
          cpu    = "500m"
        }
      }
    }
  }
}