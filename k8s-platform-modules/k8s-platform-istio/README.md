# Istio Terraform Module

This Terraform module deploys Istio service mesh components on a Kubernetes cluster, including Istiod (control plane) and Ingress Gateway.

## Features

- Modular installation of Istio components
- Configurable resource management
- Autoscaling support
- Distributed tracing integration
- Telemetry and monitoring
- Custom Gateway configuration
- TLS termination support
- Highly configurable service mesh settings

## Requirements

- Terraform >= 1.0.0
- Kubernetes cluster >= 1.21.0
- Helm provider >= 2.0.0
- Kubectl provider >= 1.14.0

## Usage

### Basic Installation

```hcl
module "istio" {
  source = "path/to/istio-module"

  namespace        = "istio-system"
  chart_version    = "1.20.0"
  
  # Enable components
  install_base            = true
  install_istiod          = true
  install_ingress_gateway = true
}
```

### Production Configuration

```hcl
module "istio" {
  source = "path/to/istio-module"

  namespace     = "istio-system"
  chart_version = "1.20.0"

  # Istiod configuration
  pilot_resources = {
    requests = {
      cpu    = "500m"
      memory = "2Gi"
    }
    limits = {
      cpu    = "1000m"
      memory = "4Gi"
    }
  }

  pilot_autoscale_enabled = true
  pilot_autoscale_min     = 2
  pilot_autoscale_max     = 5

  # Gateway configuration
  gateway_resources = {
    requests = {
      cpu    = "200m"
      memory = "256Mi"
    }
    limits = {
      cpu    = "2000m"
      memory = "1024Mi"
    }
  }

  gateway_autoscaling_enabled = true
  gateway_min_replicas        = 2
  gateway_max_replicas        = 5

  # Enable monitoring and tracing
  enable_tracing    = true
  trace_sampling    = 1
  enable_telemetry  = true

  # Gateway service configuration
  gateway_service_type = "LoadBalancer"
  gateway_service_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
  }
}
```

### With Default Gateway

```hcl
module "istio" {
  source = "path/to/istio-module"

  namespace     = "istio-system"
  chart_version = "1.20.0"

  create_default_gateway = true
  default_gateway_name   = "default-gateway"
  default_gateway_hosts  = ["*.example.com"]
  default_gateway_tls_secret = "example-tls-secret"
}
```

## Examples

### Virtual Service Configuration

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: example-service
spec:
  hosts:
    - example.com
  gateways:
    - default-gateway
  http:
    - route:
        - destination