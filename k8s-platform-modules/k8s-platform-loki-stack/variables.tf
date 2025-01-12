variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = null
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "loki"
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

variable "create_s3_bucket" {
  description = "Whether to create S3 bucket"
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "S3 bucket name for Loki storage"
  type        = string
}

variable "s3_retention_days" {
  description = "Number of days to retain objects in S3"
  type        = number
  default     = 30
}

variable "chart_version" {
  description = "Version of Loki stack Helm chart"
  type        = string
  default     = "2.9.10"
}

variable "promtail_enabled" {
  description = "Whether to enable Promtail"
  type        = bool
  default     = true
}

variable "grafana_enabled" {
  description = "Whether to enable Grafana"
  type        = bool
  default     = true
}

variable "retention_period" {
  description = "Log retention period"
  type        = string
  default     = "168h" # 7 days
}

variable "storage_class_name" {
  description = "Storage class name for Loki PVC"
  type        = string
  default     = "gp2"
}

variable "storage_size" {
  description = "Storage size for Loki PVC"
  type        = string
  default     = "10Gi"
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

variable "additional_scrape_configs" {
  description = "Additional Promtail scrape configs"
  type        = string
  default     = ""
}

variable "resources" {
  description = "Resource limits and requests"
  type = object({
    loki = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
    promtail = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
  })
  default = {
    loki = {
      requests = {
        cpu    = "200m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "1000m"
        memory = "1Gi"
      }
    }
    promtail = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
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