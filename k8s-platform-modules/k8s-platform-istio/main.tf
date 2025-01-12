resource "helm_release" "istio_base" {
  count = var.install_base ? 1 : 0

  name             = "istio-base"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = var.chart_version

  values = [
    yamlencode({
      global = {
        istioNamespace = var.namespace
      }
    })
  ]
}

resource "helm_release" "istiod" {
  count = var.install_istiod ? 1 : 0

  name       = "istiod"
  namespace  = var.namespace
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = var.chart_version

  values = [
    yamlencode({
      global = {
        hub                = var.hub
        tag               = var.chart_version
        proxy = {
          resources = var.proxy_resources
        }
      }

      pilot = {
        autoscaleEnabled = var.pilot_autoscale_enabled
        autoscaleMin     = var.pilot_autoscale_min
        autoscaleMax     = var.pilot_autoscale_max
        resources        = var.pilot_resources
        traceSampling    = var.trace_sampling
      }

      meshConfig = {
        enableTracing    = var.enable_tracing
        accessLogFile    = var.access_log_file
        enableAutoMtls   = var.enable_auto_mtls
        defaultConfig = {
          holdApplicationUntilProxyStarts = true
        }
      }

      telemetry = {
        enabled = var.enable_telemetry
        v2 = {
          enabled = true
          prometheus = {
            configOverride = {
              inboundSidecar = { disable_host_header_fallback = true }
              outboundSidecar = { disable_host_header_fallback = true }
              gateway = { disable_host_header_fallback = true }
            }
          }
        }
      }
    })
  ]

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "ingress_gateway" {
  count = var.install_ingress_gateway ? 1 : 0

  name       = "istio-ingress"
  namespace  = var.gateway_namespace
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = var.chart_version

  values = [
    yamlencode({
      service = {
        type = var.gateway_service_type
        annotations = var.gateway_service_annotations
        loadBalancerIP = var.gateway_load_balancer_ip
        ports = var.gateway_service_ports
      }

      resources = var.gateway_resources

      autoscaling = {
        enabled     = var.gateway_autoscaling_enabled
        minReplicas = var.gateway_min_replicas
        maxReplicas = var.gateway_max_replicas
        targetCPUUtilizationPercentage = var.gateway_target_cpu_utilization
      }

      serviceAccount = {
        create = true
        name   = var.gateway_service_account_name
        annotations = var.gateway_service_account_annotations
      }

      nodeSelector = var.gateway_node_selector
      tolerations  = var.gateway_tolerations
    })
  ]

  depends_on = [helm_release.istiod]
}

# Create default Gateway resource
resource "kubectl_manifest" "default_gateway" {
  count = var.create_default_gateway ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "Gateway"
    metadata = {
      name      = var.default_gateway_name
      namespace = var.gateway_namespace
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = [
        {
          port = {
            number   = 80
            name     = "http"
            protocol = "HTTP"
          }
          hosts = var.default_gateway_hosts
          tls = {
            httpsRedirect = true
          }
        },
        {
          port = {
            number   = 443
            name     = "https"
            protocol = "HTTPS"
          }
          hosts = var.default_gateway_hosts
          tls = {
            mode = "SIMPLE"
            credentialName = var.default_gateway_tls_secret
          }
        }
      ]
    }
  })

  depends_on = [helm_release.ingress_gateway]
}
