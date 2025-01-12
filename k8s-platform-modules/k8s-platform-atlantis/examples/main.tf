module "atlantis" {
  source = "./k8s-platform-atlantis"

  name           = "atlantis"
  namespace      = "atlantis"
  webhook_url    = "https://atlantis.example.com"
  github_token   = var.github_token
  github_webhook_secret = var.github_webhook_secret
  
  org_whitelist = [
    "github.com/myorg/*"
  ]

  iam_role_arn = "arn:aws:iam::123456789012:role/atlantis-role"

  ingress_enabled = true
  ingress_host    = "atlantis.example.com"
  ingress_annotations = {
    "kubernetes.io/ingress.class": "nginx"
    "cert-manager.io/cluster-issuer": "letsencrypt-prod"
  }

  resources = {
    requests = {
      memory = "1Gi"
      cpu    = "500m"
    }
    limits = {
      memory = "2Gi"
      cpu    = "1000m"
    }
  }
}