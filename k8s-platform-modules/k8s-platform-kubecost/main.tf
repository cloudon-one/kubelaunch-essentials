locals {
  name = coalesce(var.name, "kubecost")
  tags = merge(
    var.tags,
    {
      "terraform-managed" = "true"
      "component"        = "kubecost"
    }
  )
}

# Create namespace for Kubecost
resource "kubernetes_namespace" "kubecost" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Create IAM role for Kubecost
resource "aws_iam_role" "kubecost" {
  count = var.create_iam_resources ? 1 : 0
  name  = "${var.cluster_name}-kubecost"

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

# Create IAM policy for Kubecost
resource "aws_iam_policy" "kubecost" {
  count       = var.create_iam_resources ? 1 : 0
  name        = "${var.cluster_name}-kubecost"
  description = "IAM policy for Kubecost"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "athena:*",
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:CreateTable",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*",
          "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:workgroup/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "pricing:GetProducts",
          "ce:GetCostAndUsage",
          "cur:GetUsageReport"
        ]
        Resource = ["*"]
      }
    ]
  })

  tags = local.tags
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "kubecost" {
  count      = var.create_iam_resources ? 1 : 0
  role       = aws_iam_role.kubecost[0].name
  policy_arn = aws_iam_policy.kubecost[0].arn
}

# Create service account
resource "kubernetes_service_account" "kubecost" {
  metadata {
    name      = local.name
    namespace = kubernetes_namespace.kubecost.metadata[0].name
    annotations = var.create_iam_resources ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.kubecost[0].arn
    } : {}
  }
}

# Deploy Kubecost using Helm
resource "helm_release" "kubecost" {
  name       = local.name
  repository = "https://kubecost.github.io/cost-analyzer/"
  chart      = "cost-analyzer"
  version    = var.chart_version
  namespace  = kubernetes_namespace.kubecost.metadata[0].name

  values = [
    templatefile("${path.module}/templates/values.yaml", {
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_key        = var.aws_secret_key
      cluster_name          = var.cluster_name
      prometheus_enabled    = var.prometheus_enabled
      grafana_enabled       = var.grafana_enabled
      service_account_name  = kubernetes_service_account.kubecost.metadata[0].name
      ingress_enabled       = var.ingress_enabled
      ingress_host          = var.ingress_host
      ingress_annotations   = var.ingress_annotations
      s3_bucket_name        = var.s3_bucket_name
      s3_region             = data.aws_region.current.name
      kubecost_token        = var.kubecost_token
      resources             = var.resources
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
