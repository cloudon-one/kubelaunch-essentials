# Cert Manager Terraform Module

This Terraform module deploys cert-manager on a Kubernetes cluster with support for Let's Encrypt, Route53 DNS challenges, and HTTP challenges.

## Features

- cert-manager Helm chart deployment
- Automatic CRD installation
- Let's Encrypt integration
- HTTP-01 and DNS-01 challenge support
- Route53 DNS integration
- AWS IAM role and policy management
- Prometheus monitoring integration
- Configurable resource limits
- Custom Helm values support

## Requirements

- Terraform >= 1.0.0
- Kubernetes cluster
- Helm provider >= 2.0.0
- AWS provider >= 4.0.0 (if using Route53)
- AWS EKS cluster with OIDC provider (if using Route53)

## Usage

### Basic Installation

```hcl
module "cert_manager" {
  source = "path/to/cert-manager-module"

  namespace        = "cert-manager"
  chart_version    = "v1.13.0"
  acme_email       = "admin@example.com"
}
```

### With Route53 DNS Challenge

```hcl
module "cert_manager" {
  source = "path/to/cert-manager-module"

  namespace        = "cert-manager"
  chart_version    = "v1.13.0"
  acme_email       = "admin@example.com"

  # Enable DNS challenge
  dns_challenge_enabled     = true
  route53_hosted_zone_id   = "ZXXXXXXXXXXXXX"
  
  # AWS IAM configuration
  create_aws_iam_role      = true
  aws_iam_role_name       = "cert-manager-role"
  aws_iam_oidc_provider   = "oidc.eks.region.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
  aws_iam_oidc_provider_arn = "arn:aws:iam::111122223333:oidc-provider/oidc.eks.region.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
  
  # Service account annotation will be automatically set
  service_account_annotations = {
    "eks.amazonaws.com/role-arn" = "arn:aws:iam::111122223333:role/cert-manager-role"
  }
}
```

### With Custom Resources

```hcl
module "cert_manager" {
  source = "path/to/cert-manager-module"

  namespace     = "cert-manager"
  chart_version = "v1.13.0"
  acme_email    = "admin@example.com"

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

  enable_prometheus_monitoring = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| release_name | Helm release name | `string` | `"cert-manager"` | no |
| namespace | Kubernetes namespace | `string` | `"cert-manager"` | no |
| create_namespace | Create namespace if it doesn't exist | `bool` | `true` | no |
| chart_version | Helm chart version | `string` | `"v1.13.0"` | no |
| install_crds | Install cert-manager CRDs | `bool` | `true` | no |
| acme_email | Email for Let's Encrypt registration | `string` | n/a | yes |
| dns_challenge_enabled | Enable DNS challenge | `bool` | `false` | no |
| route53_hosted_zone_id | Route53 hosted zone ID | `string` | `""` | no |
| aws_region | AWS region | `string` | `"us-west-2"` | no |
| create_aws_iam_role | Create AWS IAM role | `bool` | `false` | no |
| aws_iam_role_name | AWS IAM role name | `string` | `"cert-manager"` | no |
| resources | Resource limits and requests | `map(map(string))` | See variables.tf | no |

For a complete list of inputs, see [variables.tf](./variables.tf).

## Outputs

| Name | Description |
|------|-------------|
| release_name | Helm release name |
| namespace | Kubernetes namespace |
| cluster_issuer_name | Created ClusterIssuer name |
| aws_iam_role_arn | AWS IAM role ARN |

## Examples

### Creating a Certificate

After installing cert-manager, you can create certificates using the following manifest:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - example.com
    - www.example.com
```

### Using with Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
    - hosts:
        - example.com
      secretName: example-com-tls
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: example-service
                port:
                  number: 80
```

## Common Use Cases

### Production Setup with DNS Challenge

```hcl
module "cert_manager" {
  source = "path/to/cert-manager-module"

  namespace     = "cert-manager"
  chart_version = "v1.13.0"
  acme_email    = "admin@example.com"

  dns_challenge_enabled   = true
  route53_hosted_zone_id = "ZXXXXXXXXXXXXX"
  
  create_aws_iam_role      = true
  aws_iam_role_name       = "cert-manager-prod"
  aws_iam_oidc_provider   = "oidc.eks.region.amazonaws.com/id/EXAMPLE"
  
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

  enable_prometheus_monitoring = true

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### Staging Environment with HTTP Challenge

```hcl
module "cert_manager" {
  source = "path/to/cert-manager-module"

  namespace     = "cert-manager"
  chart_version = "v1.13.0"
  acme_email    = "admin@example.com"

  cluster_issuer_name = "letsencrypt-staging"
  acme_server        = "https://acme-staging-v02.api.letsencrypt.org/directory"
  
  resources = {
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
  }

  tags = {
    Environment = "staging"
    Team        = "platform"
  }
}
```

## Troubleshooting

### Common Issues

1. **Certificate Issuance Fails**
   - Check the cert-manager logs: `kubectl logs -n cert-manager -l app=cert-manager`
   - Verify ClusterIssuer status: `kubectl describe clusterissuer letsencrypt-prod`
   - Check Certificate status: `kubectl describe certificate <certificate-name>`

2. **DNS Challenge Issues**
   - Verify IAM role permissions
   - Check Route53 hosted zone ID
   - Ensure OIDC provider is configured correctly

3. **HTTP Challenge Issues**
   - Verify ingress controller is working
   - Check ingress class name
   - Ensure ports 80/443 are accessible

## Contributing

Please read our [contribution guidelines](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.