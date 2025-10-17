terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# Lambda function code
resource "local_file" "lambda_code" {
  filename = "${path.module}/lambda_function.py"
  content  = <<-EOF
import boto3
import json
import secrets as sec
from datetime import datetime

secrets_client = boto3.client('secretsmanager')

def generate_secure_password(length=32):
    """Generate a secure random password"""
    return sec.token_urlsafe(length)

def rotate_secret(secret_id):
    """Rotate a single secret"""
    try:
        # Generate new password
        new_password = generate_secure_password()

        # Update secret
        response = secrets_client.update_secret(
            SecretId=secret_id,
            SecretString=new_password
        )

        print(f"Successfully rotated secret: {secret_id}")
        print(f"Version: {response['VersionId']}")

        return {
            'secret_id': secret_id,
            'version_id': response['VersionId'],
            'status': 'success'
        }

    except Exception as e:
        print(f"Error rotating secret {secret_id}: {str(e)}")
        raise

def handler(event, context):
    """
    Lambda handler for secrets rotation

    Event structure:
    {
        "secrets": [
            "dev/argocd/admin-password",
            "dev/kong/database-password"
        ]
    }
    """

    print(f"Starting secrets rotation at {datetime.utcnow().isoformat()}")

    # Get secrets to rotate from event or use defaults
    secrets_to_rotate = event.get('secrets', ${jsonencode(var.secrets_to_rotate)})

    results = []
    errors = []

    for secret_id in secrets_to_rotate:
        try:
            result = rotate_secret(secret_id)
            results.append(result)
        except Exception as e:
            errors.append({
                'secret_id': secret_id,
                'error': str(e)
            })

    # Prepare response
    response = {
        'statusCode': 200 if not errors else 207,  # 207 = Multi-Status
        'rotated_count': len(results),
        'error_count': len(errors),
        'results': results,
        'errors': errors,
        'timestamp': datetime.utcnow().isoformat()
    }

    # If any errors occurred, print them
    if errors:
        print(f"Rotation completed with {len(errors)} errors")
        for error in errors:
            print(f"Error: {error}")
    else:
        print(f"Successfully rotated {len(results)} secrets")

    return response
EOF
}

# Create deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = local_file.lambda_code.filename
  output_path = "${path.module}/lambda_function.zip"

  depends_on = [local_file.lambda_code]
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.environment}-secrets-rotation-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "${var.environment}-secrets-rotation-lambda"
      Component = "secrets-rotation"
    }
  )
}

# Lambda execution policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Secrets Manager access policy
resource "aws_iam_role_policy" "secrets_manager_access" {
  name = "secrets-manager-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:UpdateSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:PutSecretValue"
        ]
        Resource = [
          for secret in var.secrets_to_rotate :
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${secret}*"
        ]
      }
    ]
  })
}

# KMS access for encrypted secrets
resource "aws_iam_role_policy" "kms_access" {
  name = "kms-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey"
        ]
        Resource = "arn:aws:kms:${local.region}:${local.account_id}:key/*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${local.region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "secrets_rotation" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-secrets-rotation"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 300  # 5 minutes
  memory_size      = 256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = merge(
    var.tags,
    {
      Name      = "${var.environment}-secrets-rotation"
      Component = "secrets-rotation"
    }
  )
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.secrets_rotation.function_name}"
  retention_in_days = 30

  tags = var.tags
}

# EventBridge Rule for Scheduled Rotation
resource "aws_cloudwatch_event_rule" "rotation_schedule" {
  name                = "${var.environment}-secrets-rotation-schedule"
  description         = "Trigger secrets rotation on schedule"
  schedule_expression = var.rotation_schedule

  tags = var.tags
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.rotation_schedule.name
  target_id = "SecretsRotationLambda"
  arn       = aws_lambda_function.secrets_rotation.arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secrets_rotation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rotation_schedule.arn
}

# SNS Topic for Rotation Notifications
resource "aws_sns_topic" "rotation_notifications" {
  name = "${var.environment}-secrets-rotation-notifications"

  tags = var.tags
}

# SNS Topic Subscription (Email)
resource "aws_sns_topic_subscription" "email" {
  count = length(var.notification_emails) > 0 ? 1 : 0

  topic_arn = aws_sns_topic.rotation_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_emails[0]
}

# CloudWatch Alarm for Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.environment}-secrets-rotation-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Secrets rotation Lambda function errors"
  alarm_actions       = [aws_sns_topic.rotation_notifications.arn]

  dimensions = {
    FunctionName = aws_lambda_function.secrets_rotation.function_name
  }

  tags = var.tags
}

# Lambda Insights (Enhanced Monitoring)
resource "aws_lambda_function_event_invoke_config" "lambda_config" {
  function_name = aws_lambda_function.secrets_rotation.function_name

  maximum_retry_attempts = 2

  destination_config {
    on_failure {
      destination = aws_sns_topic.rotation_notifications.arn
    }
  }
}

output "lambda_function_arn" {
  description = "ARN of the secrets rotation Lambda function"
  value       = aws_lambda_function.secrets_rotation.arn
}

output "lambda_function_name" {
  description = "Name of the secrets rotation Lambda function"
  value       = aws_lambda_function.secrets_rotation.function_name
}

output "rotation_schedule" {
  description = "Rotation schedule expression"
  value       = var.rotation_schedule
}

output "sns_topic_arn" {
  description = "ARN of the rotation notifications SNS topic"
  value       = aws_sns_topic.rotation_notifications.arn
}
