module "karpenter" {
  source = "../"  # Path to the module

  eks_cluster_name       = "demo-eks-cluster"
  cluster_oidc_provider  = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE1234567890"
  cluster_node_role_arn  = "arn:aws:iam::123456789012:role/demo-eks-cluster-node"
  
  # Optional customizations
  name                  = "demo-karpenter"
  namespace             = "karpenter"
  service_account_name  = "karpenter-controller"
  
  tags = {
    Environment = "demo"
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

# Example provider configuration
provider "aws" {
  region = "us-west-2"
}

# Example outputs
output "karpenter_role_arn" {
  value = module.karpenter.karpenter_role_arn
}

output "instance_profile_name" {
  value = module.karpenter.instance_profile_name
}