variable "release_name" {
  description = "Helm release name for external-secrets"
  type        = string
  default     = "external-secrets"
}

variable "namespace" {
  description = "Kubernetes namespace to install external-secrets"
  type        = string
  default     = "external-secrets"
}

variable "create_namespace" {
  description = "Whether to create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "Version of the external-secrets Helm chart"
  type        = string
  default     = "0.9.9"
}

variable "install_crds" {
  description = "Whether to install CRDs"
  type        = bool
  default     = true
}

variable "service_account_name" {
  description = "Name of the service account to create"
  type        = string
  default     = ""
}

variable "service_account_annotations" {
  description = "Annotations to add to the service account"
  type        = map(string)
  default     = {}
}

variable "enable_webhook" {
  description = "Whether to enable webhook"
  type        = bool
  default     = true
}

variable "enable_cert_controller" {
  description = "Whether to enable cert controller"
  type        = bool
  default     = true
}

variable "resources" {
  description = "Resource limits and requests for the controller"
  type        = map(map(string))
  default     = {
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
  }
}

variable "additional_set_values" {
  description = "Additional set values to pass to the Helm chart"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "create_aws_iam_role" {
  description = "Whether to create an AWS IAM role for external-secrets"
  type        = bool
  default     = true
}

variable "aws_iam_role_name" {
  description = "Name of the AWS IAM role for external-secrets"
  type        = string
  default     = "external-secrets-operator"
}

variable "aws_iam_oidc_provider_arn" {
  description = "ARN of the AWS IAM OIDC provider for the EKS cluster"
  type        = string
  default     = ""
}

variable "aws_iam_oidc_provider" {
  description = "URL of the AWS IAM OIDC provider for the EKS cluster"
  type        = string
  default     = ""
}

variable "enable_secrets_manager" {
  description = "Whether to enable access to AWS Secrets Manager"
  type        = bool
  default     = true
}

variable "enable_parameter_store" {
  description = "Whether to enable access to AWS Parameter Store"
  type        = bool
  default     = true
}

variable "secrets_manager_arns" {
  description = "List of Secrets Manager ARNs to grant access to"
  type        = list(string)
  default     = ["arn:aws:secretsmanager:*:*:secret:*"]
}

variable "parameter_store_arns" {
  description = "List of Parameter Store ARNs to grant access to"
  type        = list(string)
  default     = ["arn:aws:ssm:*:*:parameter/*"]
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}

variable "enable_kms" {
  description = "Whether to enable access to AWS KMS"
  type        = bool
  default     = true
}

variable "kms_key_arns" {
  description = "List of KMS Key ARNs to grant access to"
  type        = list(string)
  default     = []
}

variable "aws_region" {
  description = "AWS region for the secrets"
  type        = string
  default     = "us-west-2"
}

variable "additional_role_arns" {
  description = "List of additional IAM role ARNs that external-secrets can assume"
  type        = list(string)
  default     = []
}