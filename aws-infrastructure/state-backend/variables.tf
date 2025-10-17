variable "owner" {
  description = "Owner/organization name for resource naming"
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the existing S3 bucket for Terraform state"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
