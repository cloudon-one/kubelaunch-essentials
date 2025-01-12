# Loki Stack Terraform Module

This Terraform module deploys the complete Loki stack (Loki, Promtail, and Grafana) on Kubernetes with AWS integration. The module provides a production-ready logging solution with S3 storage backend.

## Features

- 📊 Complete Loki stack deployment using Helm
- 🪣 S3 backend for log storage
- 🔐 AWS IAM integration (IRSA)
- 📈 Promtail log collection
- 📊 Grafana dashboard integration
- 🔄 Automatic log retention and cleanup
- 🚀 Configurable resources and scaling
- 🌐 Ingress support
- 🔍 Custom scraping configurations

## Prerequisites

- Kubernetes cluster (EKS recommended)
- Terraform >= 1.0
- AWS provider >= 4.0.0
- Kubernetes provider >= 2.10.0
- Helm provider >= 2.5.0
- OIDC provider configured for EKS cluster (for IRSA)

## Architecture

```
                    ┌──────────────┐
                    │   Grafana    │
                    │  Dashboard   │
                    └──────┬───────┘
                           │
                           ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Promtail   │───►│     Loki     │◄───│     AWS      │
│Log Collector │    │Log Aggregator│    │   S3 Bucket  │
└──────────────┘    └──────────────┘    └──────────────┘
```

## Usage

### Basic Example

```hcl
module "loki_stack" {
  source = "path/to/module"

  cluster_name          = "my-eks-cluster"
  cluster_oidc_provider = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE1234567890"
  s3_bucket_name        = "my-loki-logs"
  
  namespace          = "logging"
  promtail_enabled   = true
  grafana_enabled    = true
}
```

### Production Example

```hcl
module "loki_stack" {
  source = "path/to/module"

  cluster_name          = "prod-eks-cluster"
  cluster_oidc_provider = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE1234567890"
  s3_bucket_name        = "prod-loki-logs"
  
  namespace          = "logging"
  retention_period   = "720h"  # 30 days
  s3_retention_days  = 90
  
  storage_class_name = "gp3"
  storage_size       = "100Gi"
  
  resources = {
    loki = {
      requests = {
        cpu    = "1000m"
        memory = "2Gi"
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

  ingress_enabled = true
  ingress_host    = "logs.example.com"
  ingress_annotations = {
    "kubernetes.io/ingress.class"               = "nginx"
    "cert-manager.io/cluster-issuer"           = "letsencrypt"
    "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
  }
  
  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Configuration

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| cluster_name | Name of the EKS cluster | string |
| cluster_oidc_provider | OIDC provider URL of the EKS cluster | string |
| s3_bucket_name | S3 bucket name for log storage | string |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| namespace | Kubernetes namespace | string | "loki" |
| create_iam_resources | Create IAM roles and policies | bool | true |
| create_s3_bucket | Create S3 bucket | bool | true |
| s3_retention_days | Days to retain logs in S3 | number | 30 |
| chart_version | Loki stack Helm chart version | string | "2.9.10" |
| promtail_enabled | Enable Promtail deployment | bool | true |
| grafana_enabled | Enable Grafana deployment | bool | true |
| retention_period | Log retention period | string | "168h" |
| storage_class_name | Storage class for Loki PVC | string | "gp2" |
| storage_size | Storage size for Loki PVC | string | "10Gi" |

## Components

### Loki

The main log aggregation service that:
- Stores logs in S3
- Provides log querying capabilities
- Handles log retention and cleanup

### Promtail

Log collection agent that:
- Scrapes container logs
- Adds Kubernetes metadata
- Ships logs to Loki

### Grafana

Visualization platform that:
- Provides log exploration interface
- Allows creating log dashboards
- Supports alerting

## AWS Integration

The module creates:
1. S3 bucket for log storage
2. IAM role for Loki's service account
3. IAM policy for S3 access

## Monitoring and Resource Management

### Resources

Default resource allocation:
```yaml
loki:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi
promtail:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### Metrics

Important metrics to monitor:
- Loki ingestion rate
- Query latency
- Storage utilization
- Promtail success rate

## Troubleshooting

Common issues and solutions:

1. **S3 Access Issues**
   - Verify IAM role and policy
   - Check IRSA configuration
   - Validate S3 bucket permissions

2. **High Memory Usage**
   - Adjust retention period
   - Increase resource limits
   - Consider using query limits

3. **Log Loss**
   - Check Promtail configuration
   - Verify network connectivity
   - Monitor Promtail metrics

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This module is released under the MIT License.

---

For more information about Loki, visit the [official documentation](https://grafana.com/docs/loki/latest/).