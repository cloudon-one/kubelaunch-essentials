# Kong API Gateway Terraform Module

This Terraform module deploys Kong API Gateway on Kubernetes with AWS RDS PostgreSQL backend support. The module is designed to work with existing VPC and EKS cluster infrastructure.

## Features

- 🚀 Kong API Gateway deployment using Helm
- 📦 RDS PostgreSQL database (optional)
- 🔒 Security group management
- 🔑 SSL/TLS support
- ⚡ Auto-scaling configuration
- 🔄 Load balancer integration
- 📊 Resource management
- 🎯 Customizable deployment options

## Prerequisites

- Existing AWS VPC
- Running EKS cluster
- Terraform >= 1.5
- AWS provider >= 4.0.0
- Kubernetes provider >= 2.10.0
- Helm provider >= 2.5.0

## Usage

```hcl
module "kong" {
  source = "path/to/module"

  name = "kong-gateway"
  
  # VPC Configuration
  vpc_id              = "vpc-12345678"
  database_subnet_ids = ["subnet-1234567a", "subnet-1234567b"]
  
  # Database Configuration
  create_database            = true
  database_instance_class    = "db.t3.medium"
  database_allocated_storage = 20
  database_username         = "kong"
  database_password         = "your-secure-password"
  
  # Kong Configuration
  kong_chart_version   = "2.19.0"
  kubernetes_namespace = "kong"
  kong_replica_count   = 2
  
  # Security
  allowed_cidrs       = ["10.0.0.0/8"]
  admin_allowed_cidrs = ["10.0.0.0/16"]
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Examples

### Basic Usage with External Database

```hcl
module "kong" {
  source = "path/to/module"

  name = "kong-gateway"
  
  vpc_id              = "vpc-12345678"
  database_subnet_ids = ["subnet-1234567a", "subnet-1234567b"]
  
  create_database = false
  database_host   = "your-external-db.example.com"
  database_username = "kong"
  database_password = "your-password"
  
  kubernetes_namespace = "kong"
}
```

### Production Setup with SSL

```hcl
module "kong" {
  source = "path/to/module"

  name = "kong-gateway"
  
  vpc_id              = "vpc-12345678"
  database_subnet_ids = ["subnet-1234567a", "subnet-1234567b"]
  
  create_database            = true
  database_instance_class    = "db.r5.large"
  database_allocated_storage = 50
  database_multi_az         = true
  
  kong_replica_count = 3
  enable_proxy_ssl   = true
  proxy_ssl_cert     = file("path/to/cert.pem")
  proxy_ssl_key      = file("path/to/key.pem")
  
  resources = {
    requests = {
      cpu    = "1000m"
      memory = "2Gi"
    }
    limits = {
      cpu    = "2000m"
      memory = "4Gi"
    }
  }
  
  extra_values = {
    "ingressController.ingressClass" = "kong"
    "serviceMonitor.enabled"         = "true"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0.0 |
| kubernetes | >= 2.10.0 |
| helm | >= 2.5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0.0 |
| kubernetes | >= 2.10.0 |
| helm | >= 2.5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for all resources | `string` | `null` | no |
| vpc_id | ID of the VPC where Kong will be deployed | `string` | n/a | yes |
| database_subnet_ids | List of subnet IDs for database deployment | `list(string)` | n/a | yes |
| create_database | Whether to create RDS database | `bool` | `true` | no |
| database_host | External database host when create_database is false | `string` | `null` | no |
| database_instance_class | RDS instance class | `string` | `"db.t3.medium"` | no |
| database_allocated_storage | Allocated storage for RDS in GB | `number` | `20` | no |
| database_username | Database master username | `string` | `"kong"` | no |
| database_password | Database master password | `string` | n/a | yes |
| kong_chart_version | Version of Kong Helm chart | `string` | `"2.19.0"` | no |
| kubernetes_namespace | Kubernetes namespace for Kong | `string` | `"kong"` | no |
| kong_replica_count | Number of Kong replicas | `number` | `2` | no |
| allowed_cidrs | List of CIDRs allowed to access Kong proxy | `list(string)` | `["0.0.0.0/0"]` | no |
| admin_allowed_cidrs | List of CIDRs allowed to access Kong admin API | `list(string)` | `[]` | no |
| enable_proxy_ssl | Enable SSL for Kong proxy | `bool` | `false` | no |
| proxy_ssl_cert | SSL certificate for Kong proxy | `string` | `""` | no |
| proxy_ssl_key | SSL key for Kong proxy | `string` | `""` | no |
| resources | Resource limits and requests for Kong pods | `object` | See variables.tf | no |
| extra_values | Extra values to pass to the Kong Helm chart | `map(string)` | `{}` | no |
| tags | Additional tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| database_endpoint | RDS database endpoint |
| kong_security_group_id | Security group ID for Kong |
| database_security_group_id | Security group ID for database |
| database_username | Database username |
| kong_namespace | Kubernetes namespace where Kong is deployed |

## Additional Information

### Database Backups

By default, RDS backups are enabled with a 7-day retention period. You can modify this using the `database_backup_retention_days` variable.

### Security Groups

The module creates two security groups:
1. Kong security group - For Kong API Gateway pods
2. Database security group - For RDS instance (if created)

### Auto Scaling

Kong pods are configured with Kubernetes HPA (Horizontal Pod Autoscaling) by default:
- Min replicas: 2
- Max replicas: 10
- Target CPU utilization: 70%

### SSL/TLS Support

To enable SSL:
1. Set `enable_proxy_ssl = true`
2. Provide the certificate and key using `proxy_ssl_cert` and `proxy_ssl_key`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This module is released under the MIT License.