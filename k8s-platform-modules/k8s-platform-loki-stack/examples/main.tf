provider "aws" {
  region = "us-west-2"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "loki_stack" {
  source = "../"

  cluster_name          = "my-eks-cluster"
  cluster_oidc_provider = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE1234567890"
  s3_bucket_name        = "my-loki-logs"
  
  # Optional configurations
  namespace          = "logging"
  retention_period   = "336h" # 14 days
  promtail_enabled   = true
  grafana_enabled    = true
  
  # Storage configuration
  storage_class_name = "gp3"
  storage_size       = "50Gi"
  
  # Ingress configuration
  ingress_enabled = true
  ingress_host    = "logs.example.com"
  ingress_annotations = {
    "kubernetes.io/ingress.class"               = "nginx"
    "cert-manager.io/cluster-issuer"           = "letsencrypt"
    "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
  }
  
  # Resource configuration
  resources = {
    loki = {
      requests = {
        cpu    = "500m"
        memory = "1Gi"
      }
      limits = {
        cpu    = "2000m"
        memory = "4Gi"
      }
    }
    promtail = {
      requests = {
        cpu    = "200m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
  }
}
