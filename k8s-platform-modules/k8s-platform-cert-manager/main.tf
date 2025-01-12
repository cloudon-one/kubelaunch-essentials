resource "helm_release" "cert_manager" {
  name             = var.release_name
  namespace        = var.namespace
  create_namespace = var.create_namespace
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.chart_version

  values = [
    yamlencode({
      installCRDs = var.install_crds
      
      serviceAccount = {
        create = true
        name   = var.service_account_name
        annotations = var.service_account_annotations
      }

      resources = var.resources

      securityContext = {
        enabled = true
        fsGroup = 1001
      }

      prometheus = {
        enabled = var.enable_prometheus_monitoring
        servicemonitor = {
          enabled = var.enable_prometheus_monitoring
        }
      }

      webhook = {
        enabled = var.enable_webhook
        securePort = 10250
        hostNetwork = false
      }

      extraArgs = var.extra_args
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

# ClusterIssuer for Let's Encrypt
resource "kubernetes_manifest" "cluster_issuer" {
  count = var.create_cluster_issuer ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = var.cluster_issuer_name
    }
    spec = {
      acme = {
        server = var.acme_server
        email  = var.acme_email
        privateKeySecretRef = {
          name = "${var.cluster_issuer_name}-account-key"
        }
        solvers = var.dns_challenge_enabled ? [
          {
            dns01 = {
              route53 = {
                region       = var.aws_region
                hostedZoneID = var.route53_hosted_zone_id
              }
            }
          }
        ] : [
          {
            http01 = {
              ingress = {
                class = var.ingress_class
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

# AWS IAM Role for Route53 DNS challenge
resource "aws_iam_role" "cert_manager" {
  count = var.create_aws_iam_role && var.dns_challenge_enabled ? 1 : 0
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
resource "aws_iam_role_policy" "cert_manager_route53" {
  count = var.create_aws_iam_role && var.dns_challenge_enabled ? 1 : 0
  name  = "${var.aws_iam_role_name}-route53"
  role  = aws_iam_role.cert_manager[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:GetChange",
          "route53:ListHostedZonesByName"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/${var.route53_hosted_zone_id}"
      }
    ]
  })
}