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

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # GitHub Actions OIDC thumbprints (updated as of 2024)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = merge(
    var.tags,
    {
      Name      = "GitHub Actions OIDC Provider"
      ManagedBy = "Terraform"
      Purpose   = "CI/CD"
    }
  )
}

# IAM Role for GitHub Actions - Terraform Operations
resource "aws_iam_role" "github_actions_terraform" {
  name                 = "github-actions-terraform"
  max_session_duration = 3600  # 1 hour

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              for repo in var.allowed_repositories :
              "repo:${var.github_org}/${repo}:*"
            ]
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "GitHub Actions Terraform Role"
      ManagedBy = "Terraform"
      Purpose   = "CI/CD"
    }
  )
}

# Least-Privilege Policy for Terraform Operations
resource "aws_iam_policy" "github_actions_terraform" {
  name        = "GitHubActionsTerraformAccess"
  description = "Least-privilege policy for Terraform/Terragrunt operations via GitHub Actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 State Backend Access
      {
        Sid    = "TerraformStateS3ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation"
        ]
        Resource = var.state_bucket_arns
      },
      {
        Sid    = "TerraformStateS3Objects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          for bucket in var.state_bucket_arns :
          "${bucket}/*"
        ]
      },
      # DynamoDB State Locking
      {
        Sid    = "TerraformStateLocking"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = var.dynamodb_table_arn
      },
      # KMS for State Encryption
      {
        Sid    = "TerraformStateKMS"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "kms:ViaService" = ["s3.*.amazonaws.com", "dynamodb.*.amazonaws.com"]
          }
        }
      },
      # EKS Cluster Read Access
      {
        Sid    = "EKSClusterReadAccess"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeAddon",
          "eks:ListAddons"
        ]
        Resource = "*"
      },
      # IAM Role Read Access
      {
        Sid    = "IAMRoleReadAccess"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:GetOpenIDConnectProvider"
        ]
        Resource = "*"
      },
      # IAM Role Management (limited to environment-prefixed roles)
      {
        Sid    = "IAMRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/dev-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/qa-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/prod-*"
        ]
      },
      # IAM Policy Management
      {
        Sid    = "IAMPolicyManagement"
        Effect = "Allow"
        Action = [
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/*"
      },
      # EC2 Read Access for VPC/Networking
      {
        Sid      = "EC2ReadAccess"
        Effect   = "Allow"
        Action   = ["ec2:Describe*"]
        Resource = "*"
      },
      # Secrets Manager Read (for validation)
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      },
      # Session Tagging
      {
        Sid      = "SessionTagging"
        Effect   = "Allow"
        Action   = ["sts:TagSession"]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = aws_iam_policy.github_actions_terraform.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "role_arn" {
  description = "ARN of the GitHub Actions Terraform role"
  value       = aws_iam_role.github_actions_terraform.arn
}

output "role_name" {
  description = "Name of the GitHub Actions Terraform role"
  value       = aws_iam_role.github_actions_terraform.name
}
