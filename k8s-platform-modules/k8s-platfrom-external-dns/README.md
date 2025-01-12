# External DNS Terraform Module

This Terraform module deploys External DNS on a Kubernetes cluster with support for AWS Route53 DNS management.

## Features

- AWS Route53 integration
- Cross-account support
- IAM role and policy management
- Prometheus monitoring integration
- Multiple source types support (Service, Ingress)
- Configurable sync policies
- Customizable DNS record ownership
- High availability configuration
- Domain filtering capabilities

## Requirements

- Terraform >= 1.0.0
- Kubernetes cluster
- Helm provider >= 2.0.0
- AWS provider >= 4.0.0
- AWS EKS cluster with OIDC provider

## Usage

### Basic Installation

```hcl
module "external_dns" {
  source = "path/to/external-dns-module"

  namespace    = "external-dns"
  domain_filters = ["example.com"]
}
```

### Complete AWS Route53 Setup

```hcl
module "external_dns" {
  source = "path/to/external-dns-module"

  namespace    = "external-dns"
  chart_version = "1.13.0"

  # AWS Configuration
  create_aws_iam_role      = true
  aws_iam_role_name       = "external-dns-role"
  aws_iam_oidc_provider   = "oidc.eks.region.amazonaws.com/id/EXAMPLE"
  aws_iam_oidc_provider_arn = "arn:aws:iam::111122223333:oidc-provider/oidc.eks.region.amazonaws.com/id/EXAMPLE"
  
  # DNS Configuration
  domain_filters  = ["example.com"]
  zone_id_filters = ["Z0123456789ABCDEF"]
  
  # Service account annotation will be set automatically
  service_account_annotations = {
    "eks.amazonaws.com/role-arn" = "arn:aws:iam::111122223333:role/external-dns-role"
  }

  # Sync Configuration
  sync_policy   = "upsert-only"
  registry_type = "txt"
  txt_owner_id  = "my-cluster"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### High Availability Production Setup

```hcl
module "external_dns" {
  source = "path/to/external-dns-module"

  namespace    = "external-dns"
  chart_version = "1.13.0"

  # High Availability Settings
  replica_count = 2
  priority_class_name = "system-cluster-critical"

  # Resource Configuration
  resources = {
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }

  # Monitoring
  enable_metrics = true
  enable_service_monitor = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| release_name | Helm release name | `string` | `"external-dns"` | no |
| namespace | Kubernetes namespace | `string` | `"external-dns"` | no |
| create_namespace | Create namespace if it doesn't exist | `bool` | `true` | no |
| chart_version | Helm chart version | `string` | `"1.13.0"` | no |
| dns_provider | DNS provider to use | `string` | `"aws"` | no |
| domain_filters | Domain filters | `list(string)` | `[]` | no |
| zone_id_filters | Zone ID filters | `list(string)` | `[]` | no |
| sync_policy | DNS sync policy | `string` | `"upsert-only"` | no |
| replica_count | Number of replicas | `number` | `1` | no |
| create_aws_iam_role | Create AWS IAM role | `bool` | `true` | no |
| aws_region | AWS region | `string` | `"us-west-2"` | no |

For a complete list of inputs, see [variables.tf](./variables.tf).

## Outputs

| Name | Description |
|------|-------------|
| release_name | Helm release name |
| namespace | Kubernetes namespace |
| aws_iam_role_arn | AWS IAM role ARN |
| service_account_name | Service account name |

## Examples

### Cross-Account Setup

```hcl
module "external_dns" {
  source = "path/to/external-dns-module"

  namespace    = "external-dns"
  
  aws_assume_role_arn = "arn:aws:iam::444455556666:role/external-dns-route53"
  zone_id_filters     = ["Z0123456789ABCDEF"]

  domain_filters = [
    "prod.example.com",
    "staging.example.com"
  ]
}
```

### Multiple Source Types

```hcl
module "external_dns" {
  source = "path/to/external-dns-module"

  namespace    = "external-dns"
  
  source_types = [
    "service",
    "ingress",
    "istio-gateway"
  ]

  sync_interval = "5m"
}
```

## Common Use Cases

### Service with DNS Record

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    external-dns.alpha.kubernetes.io/hostname: my-app.example.com
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
  selector:
    app: my-app
```

### Ingress with DNS Record

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    external-dns.alpha.kubernetes.io/hostname: app.example.com
spec:
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 80
```

## Troubleshooting

### Common Issues

1. **DNS Records Not Being Created**
   - Check external-dns logs: `kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns`
   - Verify IAM permissions
   - Check domain filters and zone ID filters
   - Verify service account annotations

2. **AWS Permissions Issues**
   - Verify OIDC provider configuration
   - Check IAM role trust relationship
   - Validate Route53 policy permissions

3. **Sync Issues**
   - Check sync policy configuration
   - Verify TXT record ownership
   - Check sync interval settings

### Monitoring

1. **Prometheus Metrics**
Enable metrics collection:
```hcl
enable_metrics = true
enable_service_monitor = true
```

2. **Important Metrics**
   - `external_dns_registry_records_observed`
   - `external_dns_source_errors_total`
   - `external_dns_registry_errors_total`

## Best Practices

1. **Production Setup**
   - Use multiple replicas
   - Enable monitoring
   - Set appropriate resource limits
   - Use TXT record ownership

2. **Security**
   - Limit Route53 permissions to specific hosted zones
   - Use separate IAM roles per environment
   - Enable audit logging

3. **Performance**
   - Set appropriate sync intervals
   - Use domain and zone filters
   - Configure proper resource requests/limits

## Contributing

Please read our [contribution guidelines](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.