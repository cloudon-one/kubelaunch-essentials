variable "cluster_name" {
  description = "EKScluster name"
  type = string
  default = "eks-cluster"
}

variable "iam_policy_statements" {
  description = "A list of IAM policy"
  type = list(object({
    effect = string
    actions = list(string)
    resources = list(string)
  }))
  default = [
    {
      effect = "Allow"
      actions = [
        "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DeleteLaunchTemplate",
          "pricing:GetProducts",
          "ssm:GetParameter",
          "pricing:GetProducts"
  ]
      resources = ["*"]
    }
  ]
}

variable "node_iam_role_name" {
  description = "The name of the IAM role for the EKS nodes"
  type = string
  default = "eks-nodes"
}