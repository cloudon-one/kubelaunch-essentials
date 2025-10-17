variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for log encryption"
  type        = string
  default     = null
}

variable "failed_login_threshold" {
  description = "Number of failed logins to trigger alert"
  type        = number
  default     = 10
}

variable "policy_violation_threshold" {
  description = "Number of policy violations per hour to trigger alert"
  type        = number
  default     = 50
}

variable "security_team_emails" {
  description = "List of email addresses for security team notifications"
  type        = list(string)
  default     = []
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications (stored in AWS Secrets Manager)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
