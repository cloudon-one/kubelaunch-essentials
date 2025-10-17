variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "secrets_to_rotate" {
  description = "List of secret IDs to rotate"
  type        = list(string)
  default = [
    "dev/argocd/admin-password",
    "dev/kong/database-password"
  ]
}

variable "rotation_schedule" {
  description = "EventBridge cron expression for rotation schedule"
  type        = string
  default     = "cron(0 2 1 * ? *)"  # 1st of month at 2 AM UTC
}

variable "notification_emails" {
  description = "List of email addresses for rotation notifications"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
