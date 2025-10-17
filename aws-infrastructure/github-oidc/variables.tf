variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "cloudon-one"
}

variable "allowed_repositories" {
  description = "List of repository names allowed to assume the role"
  type        = list(string)
  default = [
    "kubelaunch-essentials",
    "k8s-platform-modules"
  ]
}

variable "state_bucket_arns" {
  description = "List of S3 bucket ARNs for Terraform state"
  type        = list(string)
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  type        = string
}

variable "tags" {
  description = "Additional tags for IAM resources"
  type        = map(string)
  default     = {}
}
