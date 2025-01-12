# Terraform AWS Airflow Module

This Terraform module deploys Apache Airflow on AWS using EKS (Elastic Kubernetes Service) with supporting infrastructure including RDS, ElastiCache, and S3.

## Architecture

The module sets up the following AWS resources:
- EKS node group for running Airflow components
- RDS PostgreSQL instance for Airflow metadata database
- ElastiCache Redis cluster for Celery executor
- S3 bucket for logs and DAGs storage
- Security groups for network isolation
- IAM roles and policies for service access

## Prerequisites

- Terraform >= 1.0
- AWS provider ~> 4.0
- Kubernetes provider ~> 2.0
- Existing VPC with private subnets
- Existing EKS cluster
- AWS CLI configured with appropriate credentials

## Usage

### Basic Usage with Terragrunt

```hcl
# terragrunt.hcl
include "common" {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = "git::https://git@github.com/cloudon-one/k8s-platform-modules.git//k8s-platform-airflow?ref=dev"
}

locals {
  platform_vars = yamldecode(file(find_in_parent_folders("platform_vars.yaml")))
  tool     = basename(get_terragrunt_dir())
  platform = basename(dirname(get_terragrunt_dir()))
  tool_vars = local.platform_vars.Platform.Tools.airflow.inputs
}

inputs = merge(
  local.tool_vars,
  {
    vpc_id             = local.platform_vars.common.vpc_id
    private_subnet_ids = local.platform_vars.common.private_subnet_ids
    eks_cluster_name   = local.platform_vars.common.eks_cluster.name
  }
)
```

### Direct Terraform Usage

```hcl
module "airflow" {
  source = "git::https://git@github.com/cloudon-one/k8s-platform-modules.git//k8s-platform-airflow?ref=dev"

  environment        = "dev"
  vpc_id            = "vpc-xxxxx"
  private_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]
  airflow_version   = "2.7.1"
  instance_type     = "t3.medium"
  eks_cluster_name  = "my-cluster"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (e.g., prod, staging) | `string` | n/a | yes |
| vpc_id | VPC ID where resources will be created | `string` | n/a | yes |
| private_subnet_ids | List of private subnet IDs | `list(string)` | n/a | yes |
| airflow_version | Apache Airflow version | `string` | `"2.7.1"` | no |
| instance_type | EC2 instance type for Airflow workers | `string` | `"t3.medium"` | no |
| eks_cluster_name | Name of the EKS cluster | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| metadata_db_endpoint | Endpoint for Airflow metadata database |
| redis_endpoint | Endpoint for Airflow Redis instance |
| s3_bucket_name | Name of the S3 bucket for Airflow storage |

## Security Considerations

1. **Network Security**:
   - All components are deployed in private subnets
   - Security groups restrict access between components
   - RDS and Redis are only accessible from Airflow nodes

2. **Data Security**:
   - S3 bucket versioning is enabled
   - Database backups are enabled with 7-day retention
   - IAM roles follow principle of least privilege

## Maintenance

### Upgrading Airflow

To upgrade Airflow version:

1. Update the `airflow_version` variable
2. Run Terragrunt plan to verify changes
3. Apply the changes during a maintenance window

### Scaling

The module supports horizontal scaling through the EKS node group configuration:
- Minimum nodes: 1
- Maximum nodes: 5
- Desired nodes: 2

## Troubleshooting

Common issues and solutions:

1. **Database Connection Issues**:
   - Verify security group rules
   - Check RDS endpoint in outputs
   - Validate database credentials

2. **Node Group Scaling Issues**:
   - Check EKS cluster autoscaler logs
   - Verify IAM roles and permissions
   - Check instance type availability in the region

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Create a Pull Request

## License

This module is licensed under the MIT License.