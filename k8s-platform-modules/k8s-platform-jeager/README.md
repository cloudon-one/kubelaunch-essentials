# Jaeger Terraform Module

This Terraform module deploys Jaeger distributed tracing system on a Kubernetes cluster, including the Jaeger Operator, Jaeger instance, and optional OpenTelemetry Collector integration.

## Features

- Jaeger Operator deployment
- Configurable Jaeger instances
- Multiple storage backend support (Elasticsearch, Cassandra, Memory)
- OpenTelemetry Collector integration
- Different deployment strategies (All-in-One, Production)
- Ingress configuration
- Resource management
- Sampling configuration
- UI customization

## Requirements

- Terraform >= 1.0.0
- Kubernetes cluster >= 1.16.0
- Helm >= 3.0
- kubectl
- Optional: Elasticsearch cluster (for production setup)

## Usage

### Basic Installation (Development)

```hcl
module "jaeger" {
  source = "path/to/jaeger-module"

  operator_namespace = "jaeger-system"
  jaeger_namespace  = "jaeger"
  
  # Use simple all-in-one deployment with in-memory storage
  deployment_strategy = "allInOne"
  storage_type       = "memory"
}
```

### Production Setup with Elasticsearch

```hcl
module "jaeger" {
  source = "path/to/jaeger-module"

  operator_namespace = "jaeger-system"
  jaeger_namespace  = "jaeger"

  deployment_strategy = "production"
  storage_type       = "elasticsearch"
  
  elasticsearch_node_count = 3
  elasticsearch_resources = {
    requests = {
      cpu    = "1"
      memory = "2Gi"
    }
    limits = {
      cpu    = "2"
      memory = "4Gi"
    }
  }
  
  collector_replicas = 2
  query_replicas     = 2
  
  ingress_enabled = true
  ingress_hosts   = ["jaeger.example.com"]
  ingress_annotations = {
    "kubernetes.io/ingress.class"                = "nginx"
    "cert-manager.io/cluster-issuer"            = "letsencrypt-prod"
  }
}
```

### With OpenTelemetry Collector

```hcl
module "jaeger" {
  source = "path/to/jaeger-module"

  operator_namespace = "jaeger-system"
  jaeger_namespace  = "jaeger"
  
  install_otel_collector = true
  otel_collector_replicas = 2
  otel_collector_resources = {
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
```

## Module Inputs

### Operator Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| install_operator | Whether to install Jaeger Operator | `bool` | `true` | no |
| operator_namespace | Namespace for Jaeger Operator | `string` | `"jaeger-system"` | no |
| operator_version | Version of Jaeger Operator | `string` | `"2.45.0"` | no |
| create_namespace | Create namespace if it doesn't exist | `bool` | `true` | no |

### Jaeger Instance Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_jaeger_instance | Whether to create Jaeger instance | `bool` | `true` | no |
| jaeger_name | Name of Jaeger instance | `string` | `"jaeger"` | no |
| deployment_strategy | Deployment strategy | `string` | `"production"` | no |
| storage_type | Storage backend type | `string` | `"elasticsearch"` | no |

For a complete list of inputs, see [variables.tf](./variables.tf).

## Storage Options

### Memory (Development)
```hcl
storage_type = "memory"
```

### Elasticsearch (Production)
```hcl
storage_type = "elasticsearch"
storage_options = {
  es.server-urls = "http://elasticsearch:9200"
  es.username    = "elastic"
  es.password    = "changeme"
}
```

### Cassandra
```hcl
storage_type = "cassandra"
storage_options = {
  cassandra.servers  = "cassandra:9042"
  cassandra.keyspace = "jaeger_v1_dc1"
}
```

## Examples

### Sampling Configuration

```hcl
sampling_config = {
  default_strategy = {
    type  = "probabilistic"
    param = 0.1  # Sample 10% of traces
  }
  service_strategies = [
    {
      service = "important-service"
      type    = "probabilistic"
      param   = 1.0  # Sample 100% of traces
    }
  ]
}
```

### Using with Istio

```hcl
module "jaeger" {
  source = "path/to/jaeger-module"

  # ... other configuration ...

  agent_strategy = "Sidecar"
  agent_options = {
    "sidecar.istio.io/inject" = "true"
  }
}
```

## Troubleshooting

### Common Issues

1. **Storage Issues**
   - Verify Elasticsearch cluster is running and accessible
   - Check storage class exists
   - Verify persistence volume claims

2. **Operator Issues**
   - Check operator logs: `kubectl logs -n jaeger-system -l name=jaeger-operator`
   - Verify RBAC permissions
   - Check CRDs are installed

3. **Collection Issues**
   - Verify agent is running
   - Check collector scaling
   - Monitor collector queue size

### Monitoring

Enable metrics collection:
```hcl
collector_options = {
  "metrics-storage-type" = "prometheus"
}

query_options = {
  "metrics-storage-type" = "prometheus"
}
```

## Best Practices

### Production Setup
1. Use Elasticsearch storage
2. Enable persistence
3. Configure appropriate resource limits
4. Use multiple collector replicas
5. Enable monitoring
6. Configure sampling appropriately

### Security
1. Enable TLS
2. Configure authentication
3. Use separate namespaces
4. Apply network policies
5. Secure Elasticsearch connection

### Performance
1. Tune batch parameters
2. Configure appropriate sampling
3. Monitor resource usage
4. Scale components based on load

## Contributing

Please read our [contribution guidelines](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.