# Terraform Module - HashiCorp Vault

This Terraform module deploys HashiCorp Vault on Kubernetes using the official Helm chart. It provides a production-ready configuration with high availability, persistent storage, and security features enabled by default.

## Features

- 🔄 High Availability mode with configurable replicas
- 💾 Persistent storage for Vault data and audit logs
- 🔒 TLS enabled by default
- 🔐 Dedicated service account with configurable annotations
- 📊 UI enabled with configurable access
- ⚡ Auto-unsealing capability (when configured with cloud provider)
- 🎛️ Highly customizable through Helm values

## Prerequisites

- Kubernetes cluster
- Terraform >= 1.0.0
- Helm provider >= 2.0.0
- Kubernetes provider >= 2.0.0

## Usage

### Basic Example

```hcl
module "vault" {
  source = "path/to/vault-module"

  name      = "vault"
  namespace = "vault-system"
  replicas  = 3
}
```

### Advanced Example with AWS Integration

```hcl
module "vault" {
  source = "path/to/vault-module"

  name          = "vault"
  namespace     = "vault-system"
  replicas      = 3
  storage_class = "gp2"
  
  service_account_annotations = {
    "eks.amazonaws.com/role-arn" = "arn:aws:iam::123456789012:role/vault-role"
  }
  
  helm_values = {
    server = {
      ha = {
        raft = {
          enabled = true
        }
      }
      affinity = {
        podAntiAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = [{
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name" = "vault"
                "component"             = "server"
              }
            }
            topologyKey = "kubernetes.io/hostname"
          }]
        }
      }
      resources = {
        requests = {
          memory = "256Mi"
          cpu    = "250m"
        }
        limits = {
          memory = "512Mi"
          cpu    = "500m"
        }
      }
    }
  }
}
```

## Module Configuration

### Required Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `name` | Name of the Vault deployment | `string` | `"vault"` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `namespace` | Kubernetes namespace for Vault | `string` | `""` |
| `create_namespace` | Create the namespace if it doesn't exist | `bool` | `true` |
| `chart_version` | Version of the Vault Helm chart | `string` | `"0.27.0"` |
| `replicas` | Number of Vault replicas | `number` | `3` |
| `storage_class` | Storage class for Vault data | `string` | `"gp2"` |
| `storage_size` | Size of data storage volume | `string` | `"10Gi"` |
| `audit_storage_size` | Size of audit storage volume | `string` | `"10Gi"` |
| `service_account_annotations` | Annotations for service account | `map(string)` | `{}` |
| `namespace_labels` | Labels for namespace | `map(string)` | `{}` |
| `extra_labels` | Additional labels for all resources | `map(string)` | `{}` |
| `helm_values` | Additional Helm values | `any` | `{}` |

### Outputs

| Name | Description |
|------|-------------|
| `namespace` | The namespace where Vault is deployed |
| `release_name` | The name of the Helm release |
| `service_name` | The name of the Vault service |

## Post-Deployment Setup

After deploying Vault, you'll need to initialize and unseal it. Here's a basic process:

1. **Get the Pod Name**:
   ```bash
   export VAULT_POD=$(kubectl get pods -n <namespace> -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')
   ```

2. **Initialize Vault**:
   ```bash
   kubectl exec -n <namespace> $VAULT_POD -- vault operator init
   ```
   
   Save the unseal keys and root token securely!

3. **Unseal Vault** (repeat 3 times with different keys):
   ```bash
   kubectl exec -n <namespace> $VAULT_POD -- vault operator unseal <unseal-key>
   ```

## Auto-Unsealing

For production environments, it's recommended to configure auto-unsealing using a cloud provider KMS service. Here's an example for AWS:

```hcl
module "vault" {
  # ... other configuration ...

  helm_values = {
    server = {
      seal = {
        type = "awskms"
        config = {
          region     = "us-west-2"
          kms_key_id = "alias/vault-unseal-key"
        }
      }
    }
  }
}
```

## Production Considerations

1. **High Availability**:
   - Deploy across multiple availability zones
   - Use anti-affinity rules (included in advanced example)
   - Configure proper resource requests/limits

2. **Security**:
   - Enable audit logging
   - Use TLS for all communication
   - Implement proper RBAC
   - Regularly rotate credentials

3. **Backup**:
   - Set up regular snapshots of storage
   - Implement disaster recovery procedures
   - Test recovery procedures regularly

4. **Monitoring**:
   - Configure monitoring and alerting
   - Watch for performance metrics
   - Monitor audit logs

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This module is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.