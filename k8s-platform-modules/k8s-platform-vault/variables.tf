variable "name" {
  description = "Name of the Vault deployment"
  type        = string
  default     = "vault"
}

variable "namespace" {
  description = "Namespace where Vault will be deployed"
  type        = string
  default     = ""
}

variable "create_namespace" {
  description = "Create the namespace if it does not exist"
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "Version of the Vault Helm chart"
  type        = string
  default     = "0.28.1"
}

variable "replicas" {
  description = "Number of Vault replicas"
  type        = number
  default     = 3
}

variable "storage_class" {
  description = "Storage class for Vault data"
  type        = string
  default     = "gp2"
}

variable "storage_size" {
  description = "Size of the data storage volume"
  type        = string
  default     = "10Gi"
}

variable "audit_storage_size" {
  description = "Size of the audit storage volume"
  type        = string
  default     = "10Gi"
}

variable "service_account_annotations" {
  description = "Annotations for the service account"
  type        = map(string)
  default     = {}
}

variable "namespace_labels" {
  description = "Labels to apply to the namespace"
  type        = map(string)
  default     = {}
}

variable "extra_labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "helm_values" {
  description = "Additional values to merge with the default helm values"
  type        = any
  default     = {}
}

variable "kms_key_id" {
  description = "AWS KMS key ID for auto-unsealing"
  type        = string
}

variable "iam_role_arn" {
  description = "IAM role ARN for Vault service account"
  type        = string
}

variable "ingress_enabled" {
  description = "Enable ingress for Vault UI"
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Hostname for Vault UI ingress"
  type        = string
  default     = ""
}

variable "ingress_annotations" {
  description = "Annotations for Vault UI ingress"
  type        = map(string)
  default     = {}
}

variable "resources" {
  description = "Resource requests and limits for Vault"
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
      memory = "2Gi"
      cpu    = "1000m"
    }
    limits = {
      memory = "4Gi"
      cpu    = "2000m"
    }
  }
}

variable "ui_enabled" {
  description = "Enable Vault UI"
  type        = bool
  default     = true
}

variable "injector_enabled" {
  description = "Enable Vault injector"
  type        = bool
  default     = true
}

variable "csi_enabled" {
  description = "Enable Vault CSI provider"
  type        = bool
  default     = true
}

variable "node_selector_key" {
  description = "Key for node selector"
  type        = string
  default     = "eks.amazonaws.com/nodegroup"
}

variable "node_selector_value" {
  description = "Value for node selector"
  type        = string
  default     = "platform"
}

variable "release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "vault"
}