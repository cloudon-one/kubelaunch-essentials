output "event_rules" {
  value = module.eks_karpenter.event_rules
}

output "iam_role_arn" {
  value = module.eks_karpenter.iam_role_arn 
}

output "service_account" {
  value = module.eks_karpenter.service_account
}