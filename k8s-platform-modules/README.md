# Kubernetes Platform Terraform Modules

A collection of Terraform modules for deploying and managing a comprehensive Kubernetes platform with essential services and tools.

## 🚀 Platform Components


### Core Infrastructure
- **[Karpenter](./k8s-platform-karpenter)**: Kubernetes Node Autoscaling
- **[External DNS](./k8s-platfrom-external-dns)**: DNS Records Management
- **[Cert Manager](./k8s-platform-cert-manager)**: Certificate Management
- **[External Secrets](./k8s-platform-external-secrets)**: Secrets Management

### Service Mesh & Networking
- **[Istio](./k8s-platform-istio)**: Service Mesh
- **[Kong Gateway](./k8s-platform-kong-gw)**: API Gateway
- **[Jaeger](./k8s-platform-jeager)**: Distributed Tracing
- **vault**: Secrets management

### Observability & Monitoring
- **[Loki Stack](./k8s-platform-loki-stack)**: Log Aggregation
- **[Kubecost](./k8s-platform-kubecost)**: Cost Management
- **[ArgoCD](./k8s-platform-argocd)**: GitOps & Deployment Management

### Platform Tools
- **[Airflow](./k8s-platform-airflow)**: Workflow Management
- **[Atlantis](./k8s-platform-atlantis)**: Terraform Automation
- **[Vault](./k8s-platform-vault)**: Secrets Management

## 📋 Prerequisites

- Terraform >= 1.5.0
- Kubernetes cluster (tested with EKS)
- kubectl configured to access your cluster
- Helm 3.x
- AWS CLI configured (if using AWS services)

## 🏗️ Architecture

### Platform Components
```mermaid
graph TB
    subgraph External["External Access"]
        DNS[External DNS]
        KongGW[Kong Gateway]
    end

    subgraph Security["Security & Identity"]
        Cert[Cert Manager]
        Vault[HashiCorp Vault]
        ExtSecrets[External Secrets]
    end

    subgraph ServiceMesh["Service Mesh"]
        Istio[Istio Control Plane]
        IstioDP[Istio Data Plane]
        Jaeger[Jaeger Tracing]
    end

    subgraph Observability["Observability Stack"]
        Loki[Loki Stack]
        Kubecost[Kubecost]
    end

    subgraph Automation["Platform Automation"]
        ArgoCD[ArgoCD]
        Atlantis[Atlantis]
        Airflow[Apache Airflow]
    end

    subgraph Infrastructure["Infrastructure Management"]
        Karpenter[Karpenter]
    end

    %% External Access connections
    DNS --> KongGW
    KongGW --> Istio
    
    %% Security connections
    Cert --> KongGW
    Cert --> Istio
    Vault --> ExtSecrets
    ExtSecrets --> ArgoCD
    
    %% Service Mesh connections
    Istio --> IstioDP
    IstioDP --> Jaeger
    
    %% Observability connections
    IstioDP --> Loki
    Kubecost --> Karpenter
    
    %% Automation connections
    ArgoCD --> IstioDP
    Atlantis --> Infrastructure
    
    %% Infrastructure connections
    Karpenter --> Infrastructure

    classDef default fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef highlight fill:#e8f4ea,stroke:#45b164,stroke-width:2px;
```

This diagram shows the high-level architecture of the platform, including:
- External access layer (Kong, External DNS)
- Security components (Cert Manager, Vault)
- Service mesh (Istio, Jaeger)
- Observability stack (Loki, Kubecost)
- Automation tools (ArgoCD, Atlantis, Airflow)
- Infrastructure management (Karpenter)

### Network Flow
```mermaid
flowchart LR
    subgraph Internet["External Traffic"]
        Client[Client]
    end

    subgraph IngressLayer["Ingress Layer"]
        DNS[External DNS]
        Cert[Cert Manager]
        Kong[Kong Gateway]
    end

    subgraph MeshLayer["Service Mesh Layer"]
        IstioGW[Istio Gateway]
        IstioCP[Istio Control Plane]
    end

    subgraph Services["Service Layer"]
        Service1[Service A]
        Service2[Service B]
        Service3[Service C]
    end

    subgraph Observability["Observability"]
        Jaeger
        Loki
    end

    Client --> DNS
    DNS --> Kong
    Cert --> Kong
    Kong --> IstioGW
    IstioGW --> IstioCP
    IstioCP --> Service1
    IstioCP --> Service2
    IstioCP --> Service3
    IstioCP -.-> Jaeger
    Service1 -.-> Loki
    Service2 -.-> Loki
    Service3 -.-> Loki

    classDef client fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef ingress fill:#e8f4ea,stroke:#45b164,stroke-width:2px;
    classDef mesh fill:#e6f3ff,stroke:#2d8cf0,stroke-width:2px;
    classDef service fill:#fff3e6,stroke:#ff9900,stroke-width:2px;
    classDef observability fill:#f9e6ff,stroke:#9900cc,stroke-width:2px;

    class Client client;
    class DNS,Kong,Cert ingress;
    class IstioGW,IstioCP mesh;
    class Service1,Service2,Service3 service;
    class Jaeger,Loki observability;
```

This diagram illustrates:
- External traffic flow
- Ingress configuration
- Service mesh routing
- Observability integration

### Configuration Management
```mermaid
flowchart TD
    subgraph GitOps["GitOps Workflow"]
        Git[Git Repository]
        ArgoCD[ArgoCD]
        Atlantis[Atlantis]
    end

    subgraph Secrets["Secrets Management"]
        Vault[HashiCorp Vault]
        ExtSecrets[External Secrets]
        SecretStore[Secret Store]
    end

    subgraph Config["Configuration"]
        Config1[Infrastructure Code]
        Config2[Application Config]
        Config3[Security Policies]
    end

    subgraph Platform["Platform Services"]
        Service1[Service A]
        Service2[Service B]
        Monitoring[Monitoring Stack]
    end

    Git --> ArgoCD
    Git --> Atlantis
    Atlantis --> Config1
    ArgoCD --> Config2
    ArgoCD --> Config3
    
    Vault --> ExtSecrets
    ExtSecrets --> SecretStore
    SecretStore --> Service1
    SecretStore --> Service2
    
    Service1 --> Monitoring
    Service2 --> Monitoring

    classDef git fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef secrets fill:#e8f4ea,stroke:#45b164,stroke-width:2px;
    classDef config fill:#e6f3ff,stroke:#2d8cf0,stroke-width:2px;
    classDef services fill:#fff3e6,stroke:#ff9900,stroke-width:2px;

    class Git,ArgoCD,Atlantis git;
    class Vault,ExtSecrets,SecretStore secrets;
    class Config1,Config2,Config3 config;
    class Service1,Service2,Monitoring services;
```
This diagram shows:
- GitOps workflows
- Secrets management
- Configuration distribution
- Service integration

## 🛠️ Module Structure

Each module follows a consistent structure:

```
k8s-platform-<component>/
├── README.md           # Module documentation
├── main.tf             # Main Terraform configuration
├── variables.tf        # Input variables
├── outputs.tf          # Output values
├── versions.tf         # Provider & version constraints
├── examples/           # Example implementations
│   └── main.tf
└── templates/          # Helm values templates
    └── values.yaml
```

## 🚀 Quick Start

1. Clone the repository:
```bash
git clone https://github.com/cloudon-one/k8s-platform-modules.git
```

2. Choose the modules you need and create your configuration:
```hcl
module "cert_manager" {
  source = "./k8s-platform-cert-manager"
  # ... configuration ...
}

module "external_dns" {
  source = "./k8s-platform-external-dns"
  # ... configuration ...
}

# Add more modules as needed
```

## 📦 Available Modules

### Core Infrastructure

#### Karpenter
```hcl
module "karpenter" {
  source = "./k8s-platform-karpenter"
  cluster_name = "my-cluster"
}
```

#### External DNS
```hcl
module "external_dns" {
  source = "./k8s-platfrom-external-dns"
  domain = "example.com"
}
```

### Service Mesh & Networking

#### Istio
```hcl
module "istio" {
  source = "./k8s-platform-istio"
  enable_monitoring = true
}
```

#### Kong Gateway
```hcl
module "kong" {
  source = "./k8s-platform-kong-gw"
  enable_proxy_protocol = true
}
```

### Observability & Monitoring

#### Loki Stack
```hcl
module "loki" {
  source = "./k8s-platform-loki-stack"
  retention_days = 30
}
```

## 🔧 Configuration

Each module has its own configuration options. Please refer to the individual module's README.md for detailed configuration options.

## 🔍 Module Dependencies

```mermaid
graph TD
    A[Cert Manager] --> B[Istio]
    A --> C[Kong Gateway]
    D[External DNS] --> C
    E[External Secrets] --> F[Applications]
    B --> G[Jaeger]
    H[ArgoCD] --> I[Platform Services]
    J[Vault] --> E
```

## 🛡️ Security Features

- HTTPS enabled by default
- RBAC configurations included
- Network policies defined
- Security context constraints
- Service mesh security

## 📊 Monitoring & Observability

- Prometheus metrics exposed
- Grafana dashboards included
- Tracing with Jaeger
- Logging with Loki
- Cost monitoring with Kubecost

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Create a pull request

## Security

- All secrets are managed through external-secrets
- TLS certificates are managed by cert-manager
- Network policies are enforced through Istio
- Regular security scanning with built-in tools

## Maintenance

### Regular Tasks

- Update component versions
- Review resource utilization
- Monitor costs with Kubecost
- Backup critical configurations

### Version Updates

Update component versions in respective `terragrunt.hcl` files:
```hcl
inputs = {
  chart_version = "x.y.z"
}
```

## Support

For issues and support:
1. Check existing issues
2. Create a new issue with:
   - Environment details
   - Error messages
   - Steps to reproduce

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## ✨ Best Practices

1. **Infrastructure as Code**
   - Use GitOps workflows
   - Implement proper state management
   - Version your infrastructure code

2. **Security**
   - Enable RBAC
   - Use network policies
   - Implement secret management
   - Enable service mesh security features

3. **Monitoring**
   - Set up proper alerting
   - Implement logging
   - Enable tracing
   - Monitor costs

4. **Scalability**
   - Use node autoscaling
   - Implement pod autoscaling
   - Configure proper resource requests/limits

## 📚 Documentation

Each module contains its own detailed README with:
- Configuration options
- Example usage
- Common pitfalls
- Troubleshooting guide

## 🤝 Support

For support, please open an issue in the repository.

## 🔄 Version Compatibility Matrix

| Module | Kubernetes Version | Terraform Version | Provider Version |
|--------|-------------------|-------------------|------------------|
| ArgoCD | >=1.24 | >=1.0.0 | >=2.0.0 |
| Istio | >=1.24 | >=1.0.0 | >=2.0.0 |
| Cert Manager | >=1.24 | >=1.0.0 | >=2.0.0 |
| Kong Gateway | >=1.24 | >=1.0.0 | >=2.0.0 |
| External DNS | >=1.24 | >=1.0.0 | >=2.0.0 |
| Vault | >=1.24 | >=1.0.0 | >=2.0.0 |

## 🔄 Upgrade Guide

Please refer to individual module READMEs for specific upgrade instructions.