# Terraform AWS ArgoCD Module

This Terraform module deploys ArgoCD on an existing EKS cluster with necessary AWS IAM roles and policies.

## Features

- Deploys ArgoCD using Helm
- Creates necessary Kubernetes namespace
- Sets up IAM roles for AWS service access
- Configures Git repositories
- Optional Dex integration for SSO
- Secure admin password management

## Prerequisites

- Terraform >= 1.0
- AWS provider ~> 4.0
- Kubernetes provider ~> 2.0
- Helm provider ~> 2.0
- Existing EKS cluster
- AWS CLI configured with appropriate credentials

## Usage

### Basic Usage with Terragrunt

```hcl
# terragrunt.hcl
include "common" {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = "git::https://github.com/your-repo/terraform-aws-argocd.git"
}

inputs = {
  environment      = "dev"
  eks_cluster_name = "my-cluster"
  argocd_version   = "2.9.0"
  admin_password   = "your-secure-password"
  
  git_repositories = [
    {
      name = "my-apps"
      url  = "https://github.com/org/apps.git"
      path = "kubernetes"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name | `string` | n/a | yes |
| eks_cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| namespace | Kubernetes namespace | `string` | `"argocd"` | no |
| argocd_version | Version of ArgoCD | `string` | n/a | yes |
| admin_password | Initial admin password | `string` | n/a | yes |
| enable_dex | Enable Dex for SSO | `bool` | `false` | no |
| git_repositories | List of Git repositories | `list(object)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| argocd_namespace | Namespace where ArgoCD is installed |
| argocd_server_service | Name of the ArgoCD server service |
| iam_role_arn | ARN of the IAM role created for ArgoCD |

## Security Considerations

1. **Authentication**:
   - Initial admin password is required
   - SSO can be enabled via Dex
   - RBAC is enabled by default

2. **Authorization**:
   - IAM roles follow principle of least privilege
   - Service account with specific permissions

3. **Network Security**:
   - Deployed in Kubernetes namespace
   - ClusterIP service by default
   - Ingress configuration separate

## Maintenance

### Upgrading ArgoCD

1. Update the `argocd_version` variable
2. Run Terragrunt plan to verify changes
3. Apply the changes during maintenance window

## Troubleshooting

Common issues and solutions:

1. **Connection Issues**:
   - Verify EKS cluster access
   - Check security group rules
   - Verify IAM roles and policies

2. **Git Repository Issues**:
   - Verify repository URLs
   - Check repository permissions
   - Validate SSH keys if using private repos

# Private Repository Support for ArgoCD

## Authentication Methods

The module supports multiple authentication methods for private repositories:

1. **SSH Authentication**
   - Private SSH keys
   - Known hosts configuration

2. **HTTPS Authentication**
   - Username/password
   - Personal access tokens

3. **GitHub Apps**
   - App ID and Installation ID
   - Private key authentication

4. **Certificate-based Authentication**
   - Client certificates
   - Custom CA certificates

## Usage Examples

### SSH Authentication

```hcl
repositories = [
  {
    name = "private-repo"
    url  = "git@github.com:org/repo.git"
    path = "kubernetes"
    credentials = {
      ssh_private_key = file("${path.module}/ssh/id_rsa")
    }
  }
]
```

### HTTPS Authentication

```hcl
repositories = [
  {
    name = "private-repo"
    url  = "https://github.com/org/repo.git"
    path = "kubernetes"
    credentials = {
      username = "git-user"
      password = "personal-access-token"
    }
  }
]
```

### GitHub App Authentication

```hcl
github_apps = [
  {
    id              = "123456"
    installation_id = "654321"
    private_key     = file("${path.module}/github/app-private-key.pem")
  }
]
```

### Certificate Authentication

```hcl
repositories = [
  {
    name = "private-repo"
    url  = "https://git.example.com/org/repo.git"
    path = "kubernetes"
    credentials = {
      tls_client_cert     = file("${path.module}/certs/client.crt")
      tls_client_cert_key = file("${path.module}/certs/client.key")
    }
  }
]

repositories_cert = [
  {
    server_name = "git.example.com"
    cert_data   = file("${path.module}/certs/ca.crt")
  }
]
```

## Security Considerations

1. **Credential Storage**
   - All credentials are stored as Kubernetes secrets
   - Secrets are namespaced to ArgoCD
   - Support for external secret management (e.g., AWS Secrets Manager)

2. **SSH Security**
   - Known hosts verification enabled by default
   - Support for custom SSH configurations
   - Private key permissions handled automatically

3. **HTTPS Security**
   - TLS verification enabled by default
   - Support for custom CA certificates
   - Optional insecure mode for testing

4. **Access Control**
   - Repository-level access control
   - Support for multiple authentication methods per repository
   - Credential rotation support

## Troubleshooting

Common issues and solutions:

1. **SSH Connection Issues**
   - Verify SSH private key format
   - Check known hosts configuration
   - Validate repository permissions

2. **HTTPS Authentication Failures**
   - Verify credentials validity
   - Check token permissions
   - Validate certificate chain

3. **GitHub App Issues**
   - Verify App installation
   - Check permissions configuration
   - Validate private key format
