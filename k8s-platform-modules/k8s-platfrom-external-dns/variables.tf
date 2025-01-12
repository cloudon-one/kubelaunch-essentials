variable "release_name" {
  description = "Helm release name for external-dns"
  type        = string
  default     = "external-dns"
}

variable "namespace" {
  description = "Kubernetes namespace to install external-dns"
  type        = string
  default     = "external-dns"
}

variable "create_namespace" {
  description = "Whether to create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "Version of the external-dns Helm chart"
  type        = string
  default     = "0.15.0"
}

variable "service_account_name" {
  description = "Name of the service account to create"
  type        = string
  default     = "external-dns"
}

variable "service_account_annotations" {
  description = "Annotations to add to the service account"
  type        = map(string)
  default     = {}
}

variable "dns_provider" {
  description = "DNS provider to use"
  type        = string
  default     = "aws"
}

variable "aws_region" {
  description = "AWS region for Route53"
  type        = string
  default     = "us-west-2"
}

variable "aws_zone_type" {
  description = "Route53 zone type (public or private)"
  type        = string
  default     = "public"
}

variable "aws_assume_role_arn" {
  description = "ARN of the AWS role to assume for Route53 access"
  type        = string
  default     = ""
}

variable "domain_filters" {
  description = "Limit possible target zones by domain suffixes"
  type        = list(string)
  default     = []
}

variable "exclude_domains" {
  description = "Exclude subdomains"
  type        = list(string)
  default     = []
}

variable "zone_id_filters" {
  description = "Limit possible target zones by zone ids"
  type        = list(string)
  default     = []
}

variable "sync_policy" {
  description = "How DNS records are synchronized between sources and providers"
  type        = string
  default     = "upsert-only" # alternatives: sync, create-only
}

variable "registry_type" {
  description = "Type of registry to use for keeping track of DNS record ownership"
  type        = string
  default     = "txt"
}

variable "txt_owner_id" {
  description = "TXT record owner ID"
  type        = string
  default     = "default"
}

variable "txt_prefix" {
  description = "Prefix to use for TXT records"
  type        = string
  default     = "external-dns-"
}

variable "sync_interval" {
  description = "Interval at which DNS records are synchronized"
  type        = string
  default     = "1m"
}

variable "resources" {
  description = "Resource limits and requests for external-dns"
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

variable "enable_metrics" {
  description = "Enable Prometheus metrics"
  type        = bool
  default     = true
}

variable "enable_service_monitor" {
  description = "Create Prometheus ServiceMonitor"
  type        = bool
  default     = false
}

variable "log_level" {
  description = "Log level"
  type        = string
  default     = "info"
}

variable "log_format" {
  description = "Log format"
  type        = string
  default     = "text"
}

variable "replica_count" {
  description = "Number of external-dns replicas"
  type        = number
  default     = 1
}

variable "priority_class_name" {
  description = "Priority class name for external-dns pods"
  type        = string
  default     = ""
}

variable "source_types" {
  description = "Types of Kubernetes resources to monitor"
  type        = list(string)
  default     = ["service", "ingress"]
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
  description = "Whether to create an AWS IAM role for external-dns"
  type        = bool
  default     = true
}

variable "aws_iam_role_name" {
  description = "Name of the AWS IAM role for external-dns"
  type        = string
  default     = "external-dns"
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