variable "release_name" {
  description = "Helm release name for cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "namespace" {
  description = "Kubernetes namespace to install cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "create_namespace" {
  description = "Whether to create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "Version of the cert-manager Helm chart"
  type        = string
  default     = "v1.14.0"
}

variable "install_crds" {
  description = "Whether to install CRDs"
  type        = bool
  default     = true
}

variable "service_account_name" {
  description = "Name of the service account to create"
  type        = string
  default     = "cert-manager"
}

variable "service_account_annotations" {
  description = "Annotations to add to the service account"
  type        = map(string)
  default     = {}
}

variable "resources" {
  description = "Resource limits and requests for cert-manager"
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

variable "enable_prometheus_monitoring" {
  description = "Whether to enable Prometheus monitoring"
  type        = bool
  default     = true
}

variable "enable_webhook" {
  description = "Whether to enable webhook"
  type        = bool
  default     = true
}

variable "extra_args" {
  description = "Additional arguments to pass to cert-manager"
  type        = list(string)
  default     = []
}

variable "additional_set_values" {
  description = "Additional set values to pass to the Helm chart"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "create_cluster_issuer" {
  description = "Whether to create a ClusterIssuer"
  type        = bool
  default     = true
}

variable "cluster_issuer_name" {
  description = "Name of the ClusterIssuer"
  type        = string
  default     = "letsencrypt-prod"
}

variable "acme_server" {
  description = "ACME server URL"
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "acme_email" {
  description = "Email address for ACME registration"
  type        = string
  default = "paltform@cloudon.work"
}

variable "dns_challenge_enabled" {
  description = "Whether to use DNS challenge instead of HTTP challenge"
  type        = bool
  default     = true
}

variable "route53_hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS challenge"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region for Route53"
  type        = string
  default     = "us-east-2"
}

variable "ingress_class" {
  description = "Ingress class for HTTP01 challenge"
  type        = string
  default     = "nginx"
}

variable "create_aws_iam_role" {
  description = "Whether to create an AWS IAM role for cert-manager"
  type        = bool
  default     = true
}

variable "aws_iam_role_name" {
  description = "Name of the AWS IAM role for cert-manager"
  type        = string
  default     = "cert-manager"
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

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}