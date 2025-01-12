# External Secrets Operator Terraform Module

This module installs the External Secrets Operator in a Kubernetes cluster using Helm.

## Requirements

- Terraform >= 1.5+
- Helm provider >= 2.0.0
- Kubernetes provider >= 2.0.0
- A Kubernetes cluster

## Usage

```hcl
module "external_secrets" {
  source = "./modules/external-secrets"

  namespace        = "external-secrets"
  chart_version    = "0.9.9"
  
  service_account_annotations = {
    "eks.amazonaws.com/role-arn" = "arn:aws:iam::123456789012:role/external-secrets-role"
  }

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
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| release_name | Helm release name | string | "external-secrets" | no |
| namespace | Kubernetes namespace | string | "external-secrets" | no |
| create_namespace | Create namespace if it doesn't exist | bool | true | no |
| chart_version | Helm chart version | string | "0.9.9" | no |
| install_crds | Whether to install CRDs | bool | true | no |
| service_account_name | Service account name | string | "external-secrets" | no |
| service_account_annotations | Service account annotations | map(string) | {} | no |
| enable_webhook | Enable webhook | bool | true | no |
| enable_cert_controller | Enable cert controller | bool | true | no |
| resources | Resource limits and requests | map(map(string)) | See default in variables | no |
| additional_set_values | Additional Helm set values | list(object) | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| release_name | The name of the Helm release |
| namespace | The namespace where external-secrets is installed |

## AWS Integration Examples

### 1. Basic EKS Setup with IRSA

```hcl
module "external_secrets" {
  source = "./modules/external-secrets"

  namespace     = "external-secrets"
  chart_version = "0.9.9"

  # AWS IAM Role configuration
  create_aws_iam_role       = true
  aws_iam_role_name        = "external-secrets-operator"
  aws_iam_oidc_provider    = "oidc.eks.region.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
  aws_iam_oidc_provider_arn = "arn:aws:iam::111122223333:oidc-provider/oidc.eks.region.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"

  # Service account annotation will be automatically set with the created role ARN
  service_account_annotations = {
    "eks.amazonaws.com/role-arn" = module.external_secrets.aws_iam_role_arn
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### 2. Example SecretStore for AWS Secrets Manager

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: external-secrets
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
```

### 3. Example ExternalSecret for AWS Secrets Manager

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: example-secret
  namespace: external-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: example-k8s-secret
  data:
  - secretKey: db-password
    remoteRef:
      key: prod/db/password
      property: password
```

### 4. Example SecretStore for AWS Parameter Store

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-parameter-store
  namespace: external-secrets
spec:
  provider:
    aws:
      service: ParameterStore
      region: us-west-2
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
```

### 5. Limited Scope Example

```hcl
module "external_secrets" {
  source = "./modules/external-secrets"

  namespace     = "external-secrets"
  chart_version = "0.9.9"

  create_aws_iam_role       = true
  aws_iam_role_name        = "external-secrets-operator"
  aws_iam_oidc_provider    = "oidc.eks.region.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
  aws_iam_oidc_provider_arn = "arn:aws:iam::111122223333:oidc-provider/oidc.eks.region.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"

  # Limit access to specific secrets and parameters
  secrets_manager_arns = [
    "arn:aws:secretsmanager:us-west-2:111122223333:secret:prod/*",
    "arn:aws:secretsmanager:us-west-2:111122223333:secret:staging/*"
  ]
  
  parameter_store_arns = [
    "arn:aws:ssm:us-west-2:111122223333:parameter/prod/*",
    "arn:aws:ssm:us-west-2:111122223333:parameter/staging/*"
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

The examples above demonstrate:
1. Basic setup with IRSA (IAM Roles for Service Accounts)
2. SecretStore configuration for AWS Secrets Manager
3. ExternalSecret configuration example
4. SecretStore configuration for AWS Parameter Store
5. Limited scope configuration with specific ARNs

## Advanced AWS Integration Examples

### 1. KMS Integration Example

```hcl
module "external_secrets" {
  source = "./modules/external-secrets"

  namespace     = "external-secrets"
  chart_version = "0.9.9"

  create_aws_iam_role        = true
  aws_iam_role_name         = "external-secrets-operator"
  aws_iam_oidc_provider     = "oidc.eks.region.amazonaws.com/id/EXAMPLE"
  aws_iam_oidc_provider_arn = "arn:aws:iam::111122223333:oidc-provider/oidc.eks.region.amazonaws.com/id/EXAMPLE"

  enable_kms = true
  kms_key_arns = [
    "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  ]

  tags = {
    Environment = "production"
  }
}
```

### 2. Cross-Account Access Example

```hcl
module "external_secrets" {
  source = "./modules/external-secrets"

  namespace     = "external-secrets"
  chart_version = "0.9.9"

  create_aws_iam_role        = true
  aws_iam_role_name         = "external-secrets-operator"
  aws_iam_oidc_provider     = "oidc.eks.region.amazonaws.com/id/EXAMPLE"
  aws_iam_oidc_provider_arn = "arn:aws:iam::111122223333:oidc-provider/oidc.eks.region.amazonaws.com/id/EXAMPLE"

  # Allow assuming roles in other accounts
  additional_role_arns = [
    "arn:aws:iam::444455556666:role/secrets-role",
    "arn:aws:iam::777788889999:role/parameters-role"
  ]
}
```

### 3. Example SecretStore with KMS Encryption

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager-kms
  namespace: external-secrets
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
      kmsKeyId: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
```

### 4. Multi-Region Example

```hcl
module "external_secrets" {
  source = "./modules/external-secrets"

  namespace     = "external-secrets"
  chart_version = "0.9.9"

  create_aws_iam_role        = true
  aws_iam_role_name         = "external-secrets-operator"
  aws_iam_oidc_provider     = "oidc.eks.region.amazonaws.com/id/EXAMPLE"
  aws_iam_oidc_provider_arn = "arn:aws:iam::111122223333:oidc-provider/oidc.eks.region.amazonaws.com/id/EXAMPLE"

  # Access secrets across multiple regions
  secrets_manager_arns = [
    "arn:aws:secretsmanager:us-west-2:111122223333:secret:*",
    "arn:aws:secretsmanager:us-east-1:111122223333:secret:*"
  ]

  parameter_store_arns = [
    "arn:aws:ssm:us-west-2:111122223333:parameter/*",
    "arn:aws:ssm:us-east-1:111122223333:parameter/*"
  ]

  kms_key_arns = [
    "arn:aws:kms:us-west-2:111122223333:key/*",
    "arn:aws:kms:us-east-1:111122223333:key/*"
  ]
}
```

### 5. Cross-Account SecretStore Example

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: cross-account-store
  namespace: external-secrets
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
      role: "arn:aws:iam::444455556666:role/secrets-role"
```

The enhanced module now includes:
1. KMS integration for encrypted secrets
2. Cross-account access capabilities
3. Multi-region support
4. Enhanced IAM permissions for listing secrets
5. STS assume role capabilities
6. Additional examples for common scenarios

Key features added:
- KMS encryption support
- Cross-account access
- Multi-region configuration
- Enhanced IAM permissions
- STS assume role capabilities