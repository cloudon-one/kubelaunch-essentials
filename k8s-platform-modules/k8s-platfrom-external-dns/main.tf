resource "helm_release" "external_dns" {
  name             = var.release_name
  namespace        = var.namespace
  create_namespace = var.create_namespace
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = var.chart_version

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = var.service_account_name
        annotations = var.service_account_annotations
      }

      provider = var.dns_provider

      aws = {
        region     = var.aws_region
        zoneType   = var.aws_zone_type
        # If you're using cross-account access
        assumeRoleArn = var.aws_assume_role_arn
      }

      domainFilters = var.domain_filters
      excludeDomains = var.exclude_domains
      zoneIdFilters = var.zone_id_filters

      policy = var.sync_policy
      registry = var.registry_type

      txtOwnerId = var.txt_owner_id
      txtPrefix = var.txt_prefix

      interval = var.sync_interval

      resources = var.resources

      metrics = {
        enabled = var.enable_metrics
        serviceMonitor = {
          enabled = var.enable_service_monitor
        }
      }

      logLevel = var.log_level
      logFormat = var.log_format

      replicaCount = var.replica_count

      priorityClassName = var.priority_class_name

      sources = var.source_types
    })
  ]

  dynamic "set" {
    for_each = var.additional_set_values
    content {
      name  = set.value.name
      value = set.value.value
    }
  }
}

# AWS IAM Role for external-dns
resource "aws_iam_role" "external_dns" {
  count = var.create_aws_iam_role ? 1 : 0
  name  = var.aws_iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.aws_iam_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.aws_iam_oidc_provider}:sub" : "system:serviceaccount:${var.namespace}:${var.service_account_name}"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Route53 access
resource "aws_iam_role_policy" "external_dns_route53" {
  count = var.create_aws_iam_role ? 1 : 0
  name  = "${var.aws_iam_role_name}-route53"
  role  = aws_iam_role.external_dns[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = [
          for zone_id in var.zone_id_filters :
          "arn:aws:route53:::hostedzone/${zone_id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = ["*"]
      }
    ]
  })
}