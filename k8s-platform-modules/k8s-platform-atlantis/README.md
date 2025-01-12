# Terraform Module - Atlantis on EKS

This Terraform module deploys Atlantis on Amazon EKS, providing automated Terraform plan and apply capabilities through pull requests.

## Features

- 🔒 Secure GitHub/GitLab integration
- 🔑 AWS authentication and IAM role integration
- 📝 Custom repository configuration support
- 🌐 Ingress configuration with TLS
- 💾 Persistent storage for plans
- 🔄 High availability setup
- 🛡️ RBAC and security configurations

## Prerequisites

- Kubernetes cluster (EKS)
- Helm 3.x
- kubectl configured to access your cluster
- GitHub/GitLab token with required permissions
- AWS credentials or IAM role
- Domain name for Atlantis webhook URL

## Usage

### Basic Example

```hcl
module "atlantis" {
  source = "path/to/atlantis-module"

  name        = "atlantis"
  namespace   = "atlantis"
  webhook_url = "https://atlantis.example.com"
  
  # GitHub configuration
  github_token         = var.github_token
  github_webhook_secret = var.github_webhook_secret
  
  # Organization whitelist
  org_whitelist = [
    "github.com/myorg/*"
  ]

  # AWS configuration
  iam_role_arn = "arn:aws:iam::123456789012:role/atlantis-role"

  # Ingress configuration
  ingress_enabled = true
  ingress_host    = "atlantis.example.com"
}
```

### Advanced Example

```hcl
module "atlantis" {
  source = "path/to/atlantis-module"

  name      = "atlantis"
  namespace = "atlantis"
  
  # Version configuration
  chart_version = "5.7.0"
  image_tag     = "atlantis-5.7.0"

  # VCS configuration
  webhook_url               = "https://atlantis.example.com"
  github_token              = var.github_token
  github_webhook_secret     = var.github_webhook_secret
  gitlab_token              = var.gitlab_token
  gitlab_webhook_secret     = var.gitlab_webhook_secret

  # AWS configuration
  iam_role_arn    = "arn:aws:iam::123456789012:role/atlantis-role"
  aws_access_key  = var.aws_access_key
  aws_secret_key  = var.aws_secret_key

  # Organization whitelist
  org_whitelist = [
    "github.com/myorg/*",
    "gitlab.com/myorg/*"
  ]

  # Storage configuration
  storage_class = "gp3"
  storage_size  = "10Gi"

  # Ingress configuration
  ingress_enabled = true
  ingress_host    = "atlantis.example.com"
  ingress_annotations = {
    "kubernetes.io/ingress.class"             = "nginx"
    "cert-manager.io/cluster-issuer"          = "letsencrypt-prod"
    "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
  }

  # Resource configuration
  resources = {
    requests = {
      memory = "1Gi"
      cpu    = "500m"
    }
    limits = {
      memory = "2Gi"
      cpu    = "1000m"
    }
  }

  # Custom repository configuration
  repo_config_json = file("${path.module}/repo-config.yaml")
}
```

## Repository Configuration

Example `repo-config.yaml`:

```yaml
repos:
  - id: /.*/
    apply_requirements: ["approved", "mergeable"]
    workflow: default
    allowed_overrides: ["workflow"]
    allow_custom_workflows: true
    delete_source_branch_on_merge: true
    pre_workflow_hooks:
      - run: terraform fmt -check
    post_workflow_hooks:
      - run: terraform-docs markdown . --output-file README.md
```

## Module Configuration

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `webhook_url` | Webhook URL for Atlantis | `string` |
| `github_token` | GitHub token | `string` |
| `github_webhook_secret` | GitHub webhook secret | `string` |
| `iam_role_arn` | IAM role ARN for service account | `string` |
| `org_whitelist` | GitHub/GitLab organization whitelist | `list(string)` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `name` | Name for Atlantis deployment | `string` | `"atlantis"` |
| `namespace` | Kubernetes namespace | `string` | `"atlantis"` |
| `chart_version` | Atlantis Helm chart version | `string` | `"4.18.0"` |
| `image_tag` | Atlantis image tag | `string` | `"v0.24.1"` |
| `storage_class` | Storage class for PV | `string` | `"gp3"` |
| `storage_size` | Storage size for PV | `string` | `"8Gi"` |
| `gitlab_token` | GitLab token | `string` | `""` |
| `gitlab_webhook_secret` | GitLab webhook secret | `string` | `""` |
| `aws_access_key` | AWS access key | `string` | `""` |
| `aws_secret_key` | AWS secret key | `string` | `""` |

## Outputs

| Name | Description |
|------|-------------|
| `namespace` | The namespace where Atlantis is deployed |
| `service_account_name` | The name of the service account |
| `webhook_url` | The webhook URL for Atlantis |

## GitHub/GitLab Setup

1. Create Personal Access Token:
   - GitHub: Settings → Developer Settings → Personal Access Tokens
   - GitLab: User Settings → Access Tokens

2. Required token permissions:
   - GitHub: `repo`, `admin:repo_hook`
   - GitLab: `api`, `read_repository`, `write_repository`

3. Configure webhook in your organization:
   - URL: Your `webhook_url` value
   - Secret: Your webhook secret
   - Events: Pull request, push events

## AWS IAM Configuration

Example IAM policy for Atlantis:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::terraform-*",
        "arn:aws:s3:::terraform-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock-*"
    }
  ]
}
```

## Security Considerations

1. **Secrets Management**:
   - Use AWS Secrets Manager or SSM Parameter Store for sensitive values
   - Rotate tokens and secrets regularly
   - Use IRSA (IAM Roles for Service Accounts) instead of static credentials

2. **Network Security**:
   - Enable TLS for ingress
   - Use network policies to restrict traffic
   - Configure webhook secret for GitHub/GitLab

3. **Access Control**:
   - Implement repository whitelisting
   - Use apply requirements (approvals)
   - Configure branch protections in VCS

## Monitoring

To enable monitoring:

1. Install Prometheus and Grafana
2. Use the provided annotations
3. Import Atlantis dashboard (if available)

## Troubleshooting

Common issues and solutions:

1. **Webhook Failures**:
   - Verify webhook URL is accessible
   - Check webhook secret
   - Validate ingress configuration

2. **Authentication Issues**:
   - Verify token permissions
   - Check IAM role configuration
   - Validate AWS credentials

3. **Plan/Apply Failures**:
   - Check repository configuration
   - Verify AWS permissions
   - Review Terraform workspace

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This module is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- HashiCorp Terraform
- Atlantis Project
- Kubernetes Community