# Random password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Security group for Airflow components
resource "aws_security_group" "airflow" {
  name_prefix = "airflow-${var.environment}-"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Name        = "airflow-main-sg"
  }
}

# IAM role for EKS node group
resource "aws_iam_role" "eks_node_group" {
  name = "airflow-${var.environment}-eks-node-group"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach required policies to node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

# RDS for Airflow metadata
resource "aws_db_instance" "airflow_metadata" {
  identifier        = "airflow-${var.environment}-metadata"
  engine            = "postgres"
  engine_version    = "13.7"
  instance_class    = "db.t3.medium"
  allocated_storage = 20
  
  db_name  = "airflow"
  username = "airflow"
  password = random_password.db_password.result
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.airflow.name
  
  backup_retention_period = 7
  skip_final_snapshot    = true
  
  tags = {
    Environment = var.environment
    Name        = "airflow-metadata-db"
  }
}

# DB subnet group
resource "aws_db_subnet_group" "airflow" {
  name       = "airflow-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = {
    Environment = var.environment
    Name        = "airflow-db-subnet-group"
  }
}

# ElastiCache subnet group
resource "aws_elasticache_subnet_group" "airflow" {
  name       = "airflow-${var.environment}-cache"
  subnet_ids = var.private_subnet_ids

  tags = {
    Environment = var.environment
    Name        = "airflow-cache-subnet-group"
  }
}

# Redis for Celery backend
resource "aws_elasticache_cluster" "airflow_celery" {
  cluster_id           = "airflow-${var.environment}-redis"
  engine              = "redis"
  node_type           = "cache.t3.micro"
  num_cache_nodes     = 1
  port                = 6379
  
  subnet_group_name    = aws_elasticache_subnet_group.airflow.name
  security_group_ids   = [aws_security_group.redis.id]
  
  tags = {
    Environment = var.environment
    Name        = "airflow-redis"
  }
}

# S3 bucket for logs and DAGs
resource "aws_s3_bucket" "airflow" {
  bucket = "airflow-${var.environment}-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Environment = var.environment
    Name        = "airflow-storage"
  }
}

resource "aws_s3_bucket_versioning" "airflow" {
  bucket = aws_s3_bucket.airflow.id
  versioning_configuration {
    status = "Enabled"
  }
}

# EKS node group for Airflow
resource "aws_eks_node_group" "airflow" {
  cluster_name    = var.eks_cluster_name
  node_group_name = "airflow-${var.environment}"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }

  instance_types = [var.instance_type]

  tags = {
    Environment = var.environment
    Name        = "airflow-nodes"
  }
}

# Security Groups
resource "aws_security_group" "rds" {
  name_prefix = "airflow-${var.environment}-rds-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.airflow.id]
  }

  tags = {
    Environment = var.environment
    Name        = "airflow-rds-sg"
  }
}

resource "aws_security_group" "redis" {
  name_prefix = "airflow-${var.environment}-redis-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.airflow.id]
  }

  tags = {
    Environment = var.environment
    Name        = "airflow-redis-sg"
  }
}

# IAM roles and policies
resource "aws_iam_role" "airflow" {
  name = "airflow-${var.environment}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "airflow_s3" {
  name = "airflow-${var.environment}-s3-policy"
  role = aws_iam_role.airflow.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.airflow.arn,
          "${aws_s3_bucket.airflow.arn}/*"
        ]
      }
    ]
  })
}