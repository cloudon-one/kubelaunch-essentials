variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = null
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "kubecost"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_oidc_provider" {
  description = "OIDC provider URL of the EKS cluster (without https://)"
  type        = string
}

variable "create_iam_resources" {
  description = "Whether to create IAM resources"
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "Version of Kubecost Helm chart"
  type        = string
  default     = "2.42.2"
}

variable "aws_access_key_id" {
  description = "AWS access key ID for Kubecost"
  type        = string
  default     = ""
}

variable "aws_secret_key" {
  description = "AWS secret key for Kubecost"
  type        = string
  default     = ""
  sensitive   = true
}

variable "prometheus_enabled" {
  description = "Whether to enable Prometheus installation"
  type        = bool
  default     = true
}

variable "grafana_enabled" {
  description = "Whether to enable Grafana installation"
  type        = bool
  default     = true
}

variable "ingress_enabled" {
  description = "Whether to enable ingress"
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Hostname for ingress"
  type        = string
  default     = ""
}

variable "ingress_annotations" {
  description = "Annotations for ingress"
  type        = map(string)
  default     = {}
}

variable "s3_bucket_name" {
  description = "S3 bucket name for cost reports"
  type        = string
}

variable "kubecost_token" {
  description = "Kubecost token for enterprise features"
  type        = string
  default     = ""
  sensitive   = true
}

variable "resources" {
  description = "Resource limits and requests"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "2Gi"
    }
  }
}

variable "extra_values" {
  description = "Extra Helm values"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}