terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_eks_cluster" "main" {
  name = var.eks_cluster_name
}

locals {
  oidc_provider = replace(data.aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
  account_id    = data.aws_caller_identity.current.account_id
  region        = data.aws_region.current.name
}

# IAM Role for External Secrets Operator
resource "aws_iam_role" "external_secrets" {
  name               = "${var.environment}-external-secrets-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${local.account_id}:oidc-provider/${local.oidc_provider}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider}:sub" = "system:serviceaccount:external-secrets:external-secrets"
            "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "${var.environment}-external-secrets-role"
      Component = "external-secrets"
      Purpose   = "IRSA"
    }
  )
}

# Policy: AWS Secrets Manager Access
resource "aws_iam_role_policy" "external_secrets_secrets_manager" {
  name = "secrets-manager-access"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${var.environment}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy: AWS Systems Manager Parameter Store Access
resource "aws_iam_role_policy" "external_secrets_parameter_store" {
  name = "parameter-store-access"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${local.region}:${local.account_id}:parameter/${var.environment}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeParameters"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy: KMS Decrypt Access
resource "aws_iam_role_policy" "external_secrets_kms" {
  name = "kms-decrypt-access"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          "arn:aws:kms:${local.region}:${local.account_id}:key/*"
        ]
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "secretsmanager.${local.region}.amazonaws.com",
              "ssm.${local.region}.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

output "role_arn" {
  description = "ARN of the External Secrets IAM role"
  value       = aws_iam_role.external_secrets.arn
}

output "role_name" {
  description = "Name of the External Secrets IAM role"
  value       = aws_iam_role.external_secrets.name
}
