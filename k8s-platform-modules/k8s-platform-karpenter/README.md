# Terraform Module for Karpenter

This Terraform module deploys Karpenter, an open-source node provisioning project built for Kubernetes, to an Amazon EKS cluster.

## Features

- Sets up necessary IAM roles and policies for Karpenter
- Deploys Karpenter using Helm
- Configures IRSA (IAM Roles for Service Accounts)
- Provides customizable settings through variables

## Prerequisites

- An existing EKS cluster
- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0
- kubectl configured to interact with your cluster
- Helm >= 3.0.0

## Usage

```hcl
module "karpenter" {
  source = "./modules/karpenter"

  cluster_name             = "my-eks-cluster"
  cluster_endpoint        = "https://example.eks.endpoint"
  cluster_oidc_provider   = "oidc.eks.region.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
  cluster_node_role_arn   = "arn:aws:iam::123456789012:role/eks-node-role"
  cluster_instance_profile = "eks-node-instance-profile"

  # Optional configurations
  namespace            = "karpenter"
  karpenter_version    = "v0.33.0"
  
  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

## Example Provisioner

After deploying Karpenter, create a provisioner to define how Karpenter should provision nodes:

```yaml
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot", "on-demand"]
    - key: node.kubernetes.io/instance-type
      operator: In
      values: ["t3.large", "t3.xlarge"]
  limits:
    resources:
      cpu: 1000
      memory: 1000Gi
  provider:
    subnetSelector:
      karpenter.sh/discovery: "true"
    securityGroupSelector:
      karpenter.sh/discovery: "true"
  ttlSecondsAfterEmpty: 30
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name for the Karpenter deployment | string | "karpenter" | no |
| namespace | Kubernetes namespace to deploy Karpenter | string | "karpenter" | no |
| service_account_name | Name of the Kubernetes service account | string | "karpenter" | no |
| cluster_name | Name of the EKS cluster | string | - | yes |
| cluster_endpoint | Endpoint of the EKS cluster | string | - | yes |
| cluster_oidc_provider | OIDC provider of the EKS cluster | string | - | yes |
| cluster_node_role_arn | ARN of the EKS node IAM role | string | - | yes |
| cluster_instance_profile | Name of the IAM instance profile | string | - | yes |
| karpenter_version | Version of Karpenter to deploy | string | "v0.33.0" | no |
| helm_values | Additional Helm values | string | "" | no |
| tags | Tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| service_account_role_arn | ARN of the IAM role used by Karpenter |
| service_account_role_name | Name of the IAM role |
| service_account_policy_arn | ARN of the IAM policy |
| namespace | Kubernetes namespace |

## License

This module is released under the MIT License.