locals {
  name = coalesce(var.name, "kong")
  tags = merge(
    var.tags,
    {
      "terraform-managed" = "true"
      "component"        = "kong-gateway"
    }
  )
}

# Security Groups
resource "aws_security_group" "kong" {
  name_prefix = "${local.name}-"
  description = "Security group for Kong API Gateway"
  vpc_id      = var.vpc_id

  tags = local.tags
}

resource "aws_security_group_rule" "kong_proxy" {
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.kong.id
  description       = "Kong proxy traffic"
}

resource "aws_security_group_rule" "kong_admin" {
  type              = "ingress"
  from_port         = 8001
  to_port           = 8001
  protocol          = "tcp"
  cidr_blocks       = var.admin_allowed_cidrs
  security_group_id = aws_security_group.kong.id
  description       = "Kong admin API"
}

resource "aws_security_group_rule" "kong_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kong.id
}

# RDS Database
resource "aws_db_subnet_group" "kong" {
  count       = var.create_database ? 1 : 0
  name_prefix = "${local.name}-"
  subnet_ids  = var.database_subnet_ids
  tags        = local.tags
}

resource "aws_security_group" "database" {
  count       = var.create_database ? 1 : 0
  name_prefix = "${local.name}-db-"
  description = "Security group for Kong database"
  vpc_id      = var.vpc_id

  tags = local.tags
}

resource "aws_security_group_rule" "database_ingress" {
  count             = var.create_database ? 1 : 0
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.database[0].id
  source_security_group_id = aws_security_group.kong.id
}

resource "aws_db_instance" "kong" {
  count                  = var.create_database ? 1 : 0
  identifier_prefix      = "${local.name}-"
  engine                 = "postgres"
  engine_version         = var.postgres_engine_version
  instance_class         = var.database_instance_class
  allocated_storage      = var.database_allocated_storage
  
  db_name               = "kong"
  username             = var.database_username
  password             = var.database_password
  
  vpc_security_group_ids = [aws_security_group.database[0].id]
  db_subnet_group_name   = aws_db_subnet_group.kong[0].name
  
  backup_retention_period = var.database_backup_retention_days
  multi_az               = var.database_multi_az
  skip_final_snapshot    = true

  tags = local.tags
}

# Kong Namespace
resource "kubernetes_namespace" "kong" {
  metadata {
    name = var.kubernetes_namespace
    labels = {
      name = var.kubernetes_namespace
    }
  }
}

# Kong Secrets
resource "kubernetes_secret" "kong_database" {
  metadata {
    name      = "kong-database-password"
    namespace = kubernetes_namespace.kong.metadata[0].name
  }

  data = {
    password = var.create_database ? aws_db_instance.kong[0].password : var.database_password
  }
}

# Kong Helm Release
resource "helm_release" "kong" {
  name       = local.name
  repository = "https://charts.konghq.com"
  chart      = "kong"
  version    = var.kong_chart_version
  namespace  = kubernetes_namespace.kong.metadata[0].name

  values = [
    templatefile("${path.module}/templates/values.yaml", {
      database_host     = var.create_database ? aws_db_instance.kong[0].endpoint : var.database_host
      database_name     = "kong"
      database_username = var.create_database ? aws_db_instance.kong[0].username : var.database_username
      database_password = var.create_database ? aws_db_instance.kong[0].password : var.database_password
      replica_count     = var.kong_replica_count
      enable_proxy_ssl  = var.enable_proxy_ssl
      proxy_ssl_cert    = var.proxy_ssl_cert
      proxy_ssl_key     = var.proxy_ssl_key
      resources         = var.resources
    })
  ]

  dynamic "set" {
    for_each = var.extra_values
    content {
      name  = set.key
      value = set.value
    }
  }
}