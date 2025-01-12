variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_version" {
  description = "Version of ArgoCD to install"
  type        = string
}

variable "admin_password" {
  description = "Initial admin password for ArgoCD"
  type        = string
  sensitive   = true
}

variable "enable_dex" {
  description = "Enable Dex for SSO"
  type        = bool
  default     = false
}

variable "git_repositories" {
  description = "List of Git repositories to configure"
  type = list(object({
    name = string
    url  = string
    path = string
  }))
  default = []
}

variable "enable_monitoring" {
  description = "Enable Prometheus monitoring and alerts for ArgoCD"
  type        = bool
  default     = true
}

variable "alert_slack_webhook" {
  description = "Slack webhook URL for AlertManager notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "alert_email_to" {
  description = "Email address for AlertManager notifications"
  type        = string
  default     = ""
}

variable "metrics_retention" {
  description = "Retention period for Prometheus metrics (e.g., 15d)"
  type        = string
  default     = "7d"
}

variable "repositories" {
  description = "Git repository configurations"
  type = list(object({
    name = string
    url  = string
    path = string
    credentials = optional(object({
      username     = optional(string)
      password     = optional(string)
      ssh_private_key = optional(string)
      tls_client_cert = optional(string)
      tls_client_cert_key = optional(string)
    }))
    type = optional(string, "git")
    insecure = optional(bool, false)
  }))
  default = []
}

variable "github_apps" {
  description = "GitHub App configurations for repository access"
  type = list(object({
    id         = string
    installation_id = string
    private_key = string
  }))
  default = []
}

variable "repositories_cert" {
  description = "Custom certificates for repository servers"
  type = list(object({
    server_name = string
    cert_data   = string
  }))
  default = []
}