resource "helm_release" "external_secrets" {
  name             = var.release_name
  namespace        = var.namespace
  create_namespace = var.create_namespace
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.chart_version

  values = [
    yamlencode({
      installCRDs = var.install_crds
      serviceAccount = {
        create = true
        name   = var.service_account_name
        annotations = var.service_account_annotations
      }
      webhook = {
        create = var.enable_webhook
      }
      certController = {
        enabled = var.enable_cert_controller
      }
      resources = var.resources
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

# AWS IAM Role for External Secrets
resource "aws_iam_role" "external_secrets" {
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

# AWS IAM Policy for KMS
resource "aws_iam_role_policy" "kms" {
  count = var.create_aws_iam_role && var.enable_kms ? 1 : 0
  name  = "${var.aws_iam_role_name}-kms"
  role  = aws_iam_role.external_secrets[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arns
      }
    ]
  })
}

# AWS IAM Policy for Secrets Manager
resource "aws_iam_role_policy" "secrets_manager" {
  count = var.create_aws_iam_role && var.enable_secrets_manager ? 1 : 0
  name  = "${var.aws_iam_role_name}-secrets-manager"
  role  = aws_iam_role.external_secrets[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = var.secrets_manager_arns
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion": var.aws_region
          }
        }
      }
    ]
  })
}

# AWS IAM Policy for Parameter Store
resource "aws_iam_role_policy" "parameter_store" {
  count = var.create_aws_iam_role && var.enable_parameter_store ? 1 : 0
  name  = "${var.aws_iam_role_name}-parameter-store"
  role  = aws_iam_role.external_secrets[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:DescribeParameters"
        ]
        Resource = var.parameter_store_arns
      }
    ]
  })
}

# AWS IAM Policy for STS Assume Role
resource "aws_iam_role_policy" "sts" {
  count = var.create_aws_iam_role && length(var.additional_role_arns) > 0 ? 1 : 0
  name  = "${var.aws_iam_role_name}-sts"
  role  = aws_iam_role.external_secrets[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = var.additional_role_arns
      }
    ]
  })
}