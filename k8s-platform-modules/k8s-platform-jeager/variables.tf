variable "install_operator" {
  description = "Whether to install Jaeger Operator"
  type        = bool
  default     = true
}

variable "operator_namespace" {
  description = "Namespace for Jaeger Operator"
  type        = string
  default     = "jaeger-system"
}

variable "create_namespace" {
  description = "Create namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "operator_version" {
  description = "Version of Jaeger Operator to install"
  type        = string
  default     = "1.62.0"
}

variable "operator_service_account_name" {
  description = "Name of the operator service account"
  type        = string
  default     = "jaeger-operator"
}

variable "operator_service_account_annotations" {
  description = "Annotations for operator service account"
  type        = map(string)
  default     = {}
}

variable "operator_resources" {
  description = "Resources for Jaeger operator"
  type        = map(map(string))
  default     = {
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
}

variable "create_jaeger_instance" {
  description = "Whether to create a Jaeger instance"
  type        = bool
  default     = true
}

variable "jaeger_name" {
  description = "Name of the Jaeger instance"
  type        = string
  default     = "jaeger"
}

variable "jaeger_namespace" {
  description = "Namespace for Jaeger instance"
  type        = string
  default     = "jaeger"
}

variable "deployment_strategy" {
  description = "Deployment strategy for Jaeger (production or allInOne)"
  type        = string
  default     = "production"
}

variable "storage_type" {
  description = "Storage type (memory, cassandra, elasticsearch, badger)"
  type        = string
  default     = "elasticsearch"
}

variable "storage_options" {
  description = "Storage options"
  type        = map(string)
  default     = {}
}

variable "elasticsearch_node_count" {
  description = "Number of Elasticsearch nodes"
  type        = number
  default     = 3
}

variable "elasticsearch_resources" {
  description = "Resources for Elasticsearch"
  type        = map(map(string))
  default     = {
    requests = {
      cpu    = "1"
      memory = "2Gi"
    }
    limits = {
      cpu    = "2"
      memory = "4Gi"
    }
  }
}

variable "elasticsearch_storage_size" {
  description = "Storage size for Elasticsearch"
  type        = string
  default     = "50Gi"
}

variable "elasticsearch_storage_class" {
  description = "Storage class for Elasticsearch"
  type        = string
  default     = "gp2"
}

variable "ingress_enabled" {
  description = "Enable ingress"
  type        = bool
  default     = true
}

variable "ingress_annotations" {
  description = "Annotations for ingress"
  type        = map(string)
  default     = {}
}

variable "ingress_hosts" {
  description = "Hosts for ingress"
  type        = list(string)
  default     = []
}

variable "ingress_tls" {
  description = "TLS configuration for ingress"
  type        = list(map(any))
  default     = []
}

variable "query_replicas" {
  description = "Number of query replicas"
  type        = number
  default     = 2
}

variable "query_resources" {
  description = "Resources for query component"
  type        = map(map(string))
  default     = {
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
    requests = {
      cpu    = "250m"
      memory = "256Mi"
    }
  }
}

variable "query_service_type" {
  description = "Service type for query component"
  type        = string
  default     = "ClusterIP"
}

variable "query_options" {
  description = "Additional options for query component"
  type        = map(string)
  default     = {}
}

variable "collector_replicas" {
  description = "Number of collector replicas"
  type        = number
  default     = 2
}

variable "collector_resources" {
  description = "Resources for collector component"
  type        = map(map(string))
  default     = {
    limits = {
      cpu    = "1"
      memory = "1Gi"
    }
    requests = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

variable "collector_service_type" {
  description = "Service type for collector component"
  type        = string
  default     = "ClusterIP"
}

variable "collector_options" {
  description = "Additional options for collector component"
  type        = map(string)
  default     = {}
}

variable "agent_strategy" {
  description = "Strategy for agent deployment (DaemonSet or Sidecar)"
  type        = string
  default     = "DaemonSet"
}

variable "agent_resources" {
  description = "Resources for agent component"
  type        = map(map(string))
  default     = {
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
}

variable "agent_options" {
  description = "Additional options for agent component"
  type        = map(string)
  default     = {}
}

variable "ui_options" {
  description = "Options for Jaeger UI"
  type        = map(string)
  default     = {}
}

variable "sampling_config" {
  description = "Sampling configuration"
  type        = map(any)
  default     = {
    default_strategy = {
      type = "probabilistic"
      param = 1
    }
  }
}

variable "jaeger_annotations" {
  description = "Annotations for Jaeger instance"
  type        = map(string)
  default     = {}
}

variable "jaeger_labels" {
  description = "Labels for Jaeger instance"
  type        = map(string)
  default     = {}
}

variable "install_otel_collector" {
  description = "Whether to install OpenTelemetry Collector"
  type        = bool
  default     = true
}

variable "otel_collector_replicas" {
  description = "Number of OpenTelemetry Collector replicas"
  type        = number
  default     = 1
}

variable "otel_collector_resources" {
  description = "Resources for OpenTelemetry Collector"
  type        = map(map(string))
  default     = {
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
    requests = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }
}