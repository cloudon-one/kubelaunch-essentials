# Kubecost Terraform Module

This Terraform module deploys Kubecost on Kubernetes with AWS integration. Kubecost provides real-time cost visibility and insights for your Kubernetes clusters.

## Features

- 📊 Kubecost deployment with Helm
- 🔐 AWS IAM integration (IRSA)
- 📈 Prometheus and Grafana integration
- 🪣 S3 bucket integration for cost reports
- 🌐 Ingress configuration
- 🚀 Resource management
- 📝 Customizable deployment options

## Prerequisites

- Kubernetes cluster (EKS recommended)
- Terraform >= 1.0
- AWS provider >= 4.0.0
- Kubernetes provider >= 2.10.0
- Helm provider >= 2.5.0
- S3 bucket for cost reports

## Usage

```hcl
module "kubecost" {
  source = "path/to/module"

  cluster_name          = "my-eks-cluster"
  cluster_oidc_provider = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE1234567890"
  s3_bucket_name        = "my-kubecost-bucket"
  
  namespace         = "kubecost"
  prometheus_enabled = true
  grafana_enabled   = true
}
```

## AWS Integration

The module creates the following AWS resources:
- IAM role for IRSA (optional)
- IAM policy for accessing AWS services
- Service account with IAM role annotation

## Additional Features

### Ingress Configuration

Enable an