variable "namespace" {
  description = "Namespace to install Istio components"
  type        = string
  default     = "istio-system"
}

variable "create_namespace" {
  description = "Create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "Version of Istio to install"
  type        = string
  default     = "1.20.0"
}

variable "install_base" {
  description = "Install Istio base chart"
  type        = bool
  default     = true
}

variable "install_istiod" {
  description = "Install Istiod"
  type        = bool
  default     = true
}

variable "install_ingress_gateway" {
  description = "Install Ingress Gateway"
  type        = bool
  default     = true
}

variable "hub" {
  description = "Container registry to pull Istio images from"
  type        = string
  default     = "docker.io/istio"
}

variable "pilot_autoscale_enabled" {
  description = "Enable autoscaling for Istiod"
  type        = bool
  default     = true
}

variable "pilot_autoscale_min" {
  description = "Minimum replicas for Istiod"
  type        = number
  default     = 1
}

variable "pilot_autoscale_max" {
  description = "Maximum replicas for Istiod"
  type        = number
  default     = 5
}

variable "pilot_resources" {
  description = "Resource limits and requests for Istiod"
  type        = map(map(string))
  default     = {
    requests = {
      cpu    = "500m"
      memory = "2Gi"
    }
    limits = {
      cpu    = "1000m"
      memory = "4Gi"
    }
  }
}

variable "proxy_resources" {
  description = "Resource limits and requests for Istio proxy"
  type        = map(map(string))
  default     = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }
}

variable "enable_tracing" {
  description = "Enable distributed tracing"
  type        = bool
  default     = true
}

variable "trace_sampling" {
  description = "Percentage of traces to sample"
  type        = number
  default     = 1
}

variable "access_log_file" {
  description = "Access log file path"
  type        = string
  default     = "/dev/stdout"
}

variable "enable_auto_mtls" {
  description = "Enable auto mTLS"
  type        = bool
  default     = true
}

variable "enable_telemetry" {
  description = "Enable telemetry v2"
  type        = bool
  default     = true
}

variable "gateway_namespace" {
  description = "Namespace for Ingress Gateway"
  type        = string
  default     = "istio-system"
}

variable "gateway_service_type" {
  description = "Service type for Ingress Gateway"
  type        = string
  default     = "LoadBalancer"
}

variable "gateway_service_annotations" {
  description = "Service annotations for Ingress Gateway"
  type        = map(string)
  default     = {}
}

variable "gateway_load_balancer_ip" {
  description = "Load balancer IP for Ingress Gateway"
  type        = string
  default     = ""
}

variable "gateway_service_ports" {
  description = "Service ports for Ingress Gateway"
  type        = list(map(string))
  default     = [
    {
      name = "http2"
      port = 80
      targetPort = 80
    },
    {
      name = "https"
      port = 443
      targetPort = 443
    }
  ]
}

variable "gateway_resources" {
  description = "Resource limits and requests for Ingress Gateway"
  type        = map(map(string))
  default     = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "2000m"
      memory = "1024Mi"
    }
  }
}

variable "gateway_autoscaling_enabled" {
  description = "Enable autoscaling for Ingress Gateway"
  type        = bool
  default     = true
}

variable "gateway_min_replicas" {
  description = "Minimum replicas for Ingress Gateway"
  type        = number
  default     = 1
}

variable "gateway_max_replicas" {
  description = "Maximum replicas for Ingress Gateway"
  type        = number
  default     = 5
}

variable "gateway_target_cpu_utilization" {
  description = "Target CPU utilization for Ingress Gateway autoscaling"
  type        = number
  default     = 80
}

variable "gateway_service_account_name" {
  description = "Service account name for Ingress Gateway"
  type        = string
  default     = "istio-ingress-gateway"
}

variable "gateway_service_account_annotations" {
  description = "Service account annotations for Ingress Gateway"
  type        = map(string)
  default     = {}
}

variable "gateway_node_selector" {
  description = "Node selector for Ingress Gateway"
  type        = map(string)
  default     = {}
}

variable "gateway_tolerations" {
  description = "Tolerations for Ingress Gateway"
  type        = list(map(string))
  default     = []
}

variable "create_default_gateway" {
  description = "Create default Gateway resource"
  type        = bool
  default     = true
}

variable "default_gateway_name" {
  description = "Name of the default Gateway resource"
  type        = string
  default     = "default-gateway"
}

variable "default_gateway_hosts" {
  description = "Hosts for the default Gateway resource"
  type        = list(string)
  default     = ["*"]
}

variable "default_gateway_tls_secret" {
  description = "TLS secret for the default Gateway resource"
  type        = string
  default     = ""
}