variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ID of the VPC where Kong will be deployed"
  type        = string
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for database deployment"
  type        = list(string)
}

variable "create_database" {
  description = "Whether to create RDS database"
  type        = bool
  default     = true
}

variable "database_host" {
  description = "External database host when create_database is false"
  type        = string
  default     = null
}

variable "postgres_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "14.7"
}

variable "database_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "database_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "database_username" {
  description = "Database master username"
  type        = string
  default     = "kong"
}

variable "database_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "database_backup_retention_days" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 7
}

variable "database_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "kong_chart_version" {
  description = "Version of Kong Helm chart"
  type        = string
  default     = "2.42.0"
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for Kong"
  type        = string
  default     = "kong"
}

variable "kong_replica_count" {
  description = "Number of Kong replicas"
  type        = number
  default     = 2
}

variable "allowed_cidrs" {
  description = "List of CIDRs allowed to access Kong proxy"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "admin_allowed_cidrs" {
  description = "List of CIDRs allowed to access Kong admin API"
  type        = list(string)
  default     = []
}

variable "enable_proxy_ssl" {
  description = "Enable SSL for Kong proxy"
  type        = bool
  default     = false
}

variable "proxy_ssl_cert" {
  description = "SSL certificate for Kong proxy"
  type        = string
  default     = ""
}

variable "proxy_ssl_key" {
  description = "SSL key for Kong proxy"
  type        = string
  default     = ""
}

variable "resources" {
  description = "Resource limits and requests for Kong pods"
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
      cpu    = "500m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "2000m"
      memory = "2Gi"
    }
  }
}

variable "extra_values" {
  description = "Extra values to pass to the Kong Helm chart"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}