module "eks_karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.26.0"
  cluster_name = var.cluster_name
  create_instance_profile = true
  create_pod_identity_association = true
  enable_irsa = true
  iam_policy_statements = var.iam_policy_statements
  node_iam_role_name = var.node_iam_role_name
}