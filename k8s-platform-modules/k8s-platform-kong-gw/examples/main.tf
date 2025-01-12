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

module "kong" {
  source = "../"

  name = "demo-kong"
  
  # VPC Configuration
  vpc_id              = "vpc-12345678"
  database_subnet_ids = ["subnet-1234567a", "subnet-1234567b", "subnet-1234567c"]
  
  # Database Configuration
  create_database              = true
  database_instance_class      = "db.t3.medium"
  database_allocated_storage   = 20
  database_username           = "kong"
  database_password           = "your-secure-password"
  database_multi_az           = false
  
  # Kong Configuration
  kong_chart_version    = "2.19.0"
  kubernetes_namespace  = "kong"
  kong_replica_count    = 2
  
  # Security
  allowed_cidrs = ["10.0.0.0/8"]
  admin_allowed_cidrs = ["10.0.0.0/16"]
  
  # Resources
  resources = {
    requests = {
      cpu    = "500m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "2000m"
      memory = "2Gi"
    }
  }
  
  # Additional Helm values
  extra_values = {
    "ingressController.ingressClass" = "kong"
    "serviceMonitor.enabled"         = "true"
  }
  
  tags = {
    Environment = "demo"
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "kong_database_endpoint" {
  value = module.kong.database_endpoint
}

output "kong_namespace" {
  value = module.kong.kong_namespace
}