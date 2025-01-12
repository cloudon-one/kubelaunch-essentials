provider "aws" {
  region = "us-west-2"
}

provider "kubernetes" {
  # EKS cluster configuration
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "kubecost" {
  source = "../"

  cluster_name          = "my-eks-cluster"
  cluster_oidc_provider = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE1234567890"
  s3_bucket_name        = "my-kubecost-bucket"
  
  # Optional configurations
  namespace         = "kubecost"
  chart_version     = "1.103.3"
  prometheus_enabled = true
  grafana_enabled   = true
  
  # Ingress configuration
  ingress_enabled = true
  ingress_host    = "kubecost.example.com"
  ingress_annotations = {
    "kubernetes.io/ingress.class"                = "nginx"
    "cert-manager.io/cluster-issuer"            = "letsencrypt"
    "nginx.ingress.kubernetes.io/ssl-redirect"  = "true"
  }
  
  # Resource limits
  resources = {
    requests = {
      cpu    = "200m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "1000m"
      memory = "4Gi"
    }
  }
  
  # Additional Helm values
  extra_values = {
    "networkCosts.enabled" = "true"
    "prometheus.server.retention" = "30d"
  }
  
  tags = {
    Environment = "production"
    Team        = "platform"
  }
}

# Outputs
output "kubecost_namespace" {
  value = module.kubecost.namespace
}

output "kubecost_role_arn" {
  value = module.kubecost.role_arn
}