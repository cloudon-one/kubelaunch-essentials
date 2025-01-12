resource "helm_release" "jaeger_operator" {
  count = var.install_operator ? 1 : 0

  name             = "jaeger-operator"
  namespace        = var.operator_namespace
  create_namespace = var.create_namespace
  repository       = "https://jaegertracing.github.io/helm-charts"
  chart            = "jaeger-operator"
  version          = var.operator_version

  values = [
    yamlencode({
      rbac = {
        clusterRole = true
      }
      serviceAccount = {
        create = true
        name   = var.operator_service_account_name
        annotations = var.operator_service_account_annotations
      }
      resources = var.operator_resources
    })
  ]
}

locals {
  elasticsearch_config = var.storage_type == "elasticsearch" ? {
    elasticsearch = {
      nodeCount = var.elasticsearch_node_count
      resources = var.elasticsearch_resources
      storage = {
        size = var.elasticsearch_storage_size
        class = var.elasticsearch_storage_class
      }
    }
  } : {}
}

resource "kubectl_manifest" "jaeger" {
  count = var.create_jaeger_instance ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "jaegertracing.io/v1"
    kind       = "Jaeger"
    metadata = {
      name      = var.jaeger_name
      namespace = var.jaeger_namespace
    }
    spec = merge({
      strategy = var.deployment_strategy

      # Storage configuration
      storage = {
        type = var.storage_type
        options = var.storage_options
      }

      # Ingress configuration
      ingress = {
        enabled = var.ingress_enabled
        annotations = var.ingress_annotations
        hosts = var.ingress_hosts
        tls = var.ingress_tls
      }

      # Query configuration
      query = {
        replicas = var.query_replicas
        resources = var.query_resources
        serviceType = var.query_service_type
        options = var.query_options
      }

      # Collector configuration
      collector = {
        replicas = var.collector_replicas
        resources = var.collector_resources
        serviceType = var.collector_service_type
        options = var.collector_options
      }

      # Agent configuration
      agent = {
        strategy = var.agent_strategy
        resources = var.agent_resources
        options = var.agent_options
      }

      # UI configuration
      ui = {
        options = var.ui_options
      }

      # Sampling configuration
      sampling = var.sampling_config

      # Additional configuration
      annotations = var.jaeger_annotations
      labels = var.jaeger_labels
    }, local.elasticsearch_config)
  })

  depends_on = [helm_release.jaeger_operator]
}

# Create OTEL Collector if enabled
resource "kubectl_manifest" "otel_collector" {
  count = var.install_otel_collector ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "OpenTelemetryCollector"
    metadata = {
      name      = "${var.jaeger_name}-otel-collector"
      namespace = var.jaeger_namespace
    }
    spec = {
      mode = "deployment"
      replicas = var.otel_collector_replicas
      resources = var.otel_collector_resources
      
      config = yamlencode({
        receivers = {
          otlp = {
            protocols = {
              grpc = {}
              http = {}
            }
          }
        }
        processors = {
          batch = {}
          memory_limiter = {
            check_interval = "1s"
            limit_mib = 1000
          }
        }
        exporters = {
          jaeger = {
            endpoint = "${var.jaeger_name}-collector:14250"
            tls = {
              insecure = true
            }
          }
        }
        service = {
          pipelines = {
            traces = {
              receivers = ["otlp"]
              processors = ["memory_limiter", "batch"]
              exporters = ["jaeger"]
            }
          }
        }
      })
    }
  })

  depends_on = [kubectl_manifest.jaeger]
}
