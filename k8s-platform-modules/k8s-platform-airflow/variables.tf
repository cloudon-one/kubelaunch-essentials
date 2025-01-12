variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "airflow_version" {
  description = "Apache Airflow version"
  type        = string
  default     = "2.7.1"
}

variable "instance_type" {
  description = "EC2 instance type for Airflow workers"
  type        = string
  default     = "t3.medium"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}