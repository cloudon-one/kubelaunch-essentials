variable "name" {
  description = "Name for the Atlantis deployment"
  type        = string
  default     = "atlantis"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "atlantis"
}

variable "create_namespace" {
  description = "Create Kubernetes namespace"
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "Atlantis Helm chart version"
  type        = string
  default     = "5.7.0"
}

variable "image_tag" {
  description = "Atlantis image tag"
  type        = string
  default     = "atlantis-5.7.0"
}

variable "github_token" {
  description = "GitHub token"
  type        = string
  sensitive   = true
}

variable "github_webhook_secret" {
  description = "GitHub webhook secret"
  type        = string
  sensitive   = true
}

variable "gitlab_token" {
  description = "GitLab token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "gitlab_webhook_secret" {
  description = "GitLab webhook secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "iam_role_arn" {
  description = "IAM role ARN for service account"
  type        = string
}

variable "webhook_url" {
  description = "Webhook URL for Atlantis"
  type        = string
}

variable "org_whitelist" {
  description = "GitHub/GitLab organization whitelist"
  type        = list(string)
}

variable "repo_config_json" {
  description = "Repository configuration JSON"
  type        = string
  default     = ""
}

variable "storage_class" {
  description = "Storage class for persistent volume"
  type        = string
  default     = "gp3"
}

variable "storage_size" {
  description = "Storage size for persistent volume"
  type        = string
  default     = "8Gi"
}

variable "ingress_enabled" {
  description = "Enable ingress"
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Ingress host"
  type        = string
}

variable "ingress_annotations" {
  description = "Ingress annotations"
  type        = map(string)
  default     = {}
}

variable "resources" {
  description = "Resource requests and limits"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
  default = {
    requests = {
      memory = "1Gi"
      cpu    = "500m"
    }
    limits = {
      memory = "2Gi"
      cpu    = "1000m"
    }
  }
}

variable "namespace_labels" {
  description = "Labels for namespace"
  type        = map(string)
  default     = {}
}

variable "service_account_annotations" {
  description = "Service account annotations"
  type        = map(string)
  default     = {}
}