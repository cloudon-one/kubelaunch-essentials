locals {
  name = coalesce(var.name, "loki")
  tags = merge(
    var.tags,
    {
      "terraform-managed" = "true"
      "component"        = "loki-stack"
    }
  )
}

# Create namespace
resource "kubernetes_namespace" "loki" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Create S3 bucket for Loki storage
resource "aws_s3_bucket" "loki" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = var.s3_bucket_name

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "loki" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.loki[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "loki" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.loki[0].id

  rule {
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = var.s3_retention_days
    }
  }
}

# Create IAM role for Loki
resource "aws_iam_role" "loki" {
  count = var.create_iam_resources ? 1 : 0
  name  = "${var.cluster_name}-loki"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.cluster_oidc_provider}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.cluster_oidc_provider}:aud" = "sts.amazonaws.com",
            "${var.cluster_oidc_provider}:sub" = "system:serviceaccount:${var.namespace}:${local.name}"
          }
        }
      }
    ]
  })

  tags = local.tags
}

# Create IAM policy for Loki
resource "aws_iam_policy" "loki" {
  count       = var.create_iam_resources ? 1 : 0
  name        = "${var.cluster_name}-loki"
  description = "IAM policy for Loki"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListObjects"
        ]
        Resource = [
          var.create_s3_bucket ? aws_s3_bucket.loki[0].arn : "arn:aws:s3:::${var.s3_bucket_name}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${var.create_s3_bucket ? aws_s3_bucket.loki[0].arn : "arn:aws:s3:::${var.s3_bucket_name}"}/*"
        ]
      }
    ]
  })

  tags = local.tags
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "loki" {
  count      = var.create_iam_resources ? 1 : 0
  role       = aws_iam_role.loki[0].name
  policy_arn = aws_iam_policy.loki[0].arn
}

# Create service account
resource "kubernetes_service_account" "loki" {
  metadata {
    name      = local.name
    namespace = kubernetes_namespace.loki.metadata[0].name
    annotations = var.create_iam_resources ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.loki[0].arn
    } : {}
  }
}

# Deploy Loki stack using Helm
resource "helm_release" "loki" {
  name       = local.name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = var.chart_version
  namespace  = kubernetes_namespace.loki.metadata[0].name

  values = [
    templatefile("${path.module}/templates/values.yaml", {
      s3_bucket_name      = var.s3_bucket_name
      s3_region          = data.aws_region.current.name
      retention_period   = var.retention_period
      service_account    = kubernetes_service_account.loki.metadata[0].name
      promtail_enabled   = var.promtail_enabled
      grafana_enabled    = var.grafana_enabled
      resources          = var.resources
      storage_class_name = var.storage_class_name
      storage_size       = var.storage_size
      ingress_enabled    = var.ingress_enabled
      ingress_host       = var.ingress_host
      ingress_annotations = var.ingress_annotations
      additional_scrape_configs = var.additional_scrape_configs
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

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}