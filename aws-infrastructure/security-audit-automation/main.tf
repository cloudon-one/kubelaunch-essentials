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

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# CloudWatch Log Group for Security Events
resource "aws_cloudwatch_log_group" "security_events" {
  name              = "/aws/eks/${var.environment}/security-events"
  retention_in_days = 90  # 90 days for compliance

  kms_key_id = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name      = "security-events"
      Component = "security-audit"
    }
  )
}

# CloudWatch Log Group for Falco
resource "aws_cloudwatch_log_group" "falco" {
  name              = "/aws/eks/${var.environment}/falco"
  retention_in_days = 90

  kms_key_id = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name      = "falco-events"
      Component = "falco"
    }
  )
}

# CloudWatch Log Group for Kyverno Policy Reports
resource "aws_cloudwatch_log_group" "kyverno" {
  name              = "/aws/eks/${var.environment}/kyverno"
  retention_in_days = 30

  kms_key_id = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name      = "kyverno-policy-reports"
      Component = "kyverno"
    }
  )
}

# Metric Filter: Failed Login Attempts
resource "aws_cloudwatch_log_metric_filter" "failed_logins" {
  name           = "failed-login-attempts"
  log_group_name = aws_cloudwatch_log_group.security_events.name
  pattern        = "[time, request_id, event_type = AuthenticationFailure*, ...]"

  metric_transformation {
    name      = "FailedLoginAttempts"
    namespace = "Security/Authentication"
    value     = "1"
  }
}

# Alarm: Excessive Failed Logins
resource "aws_cloudwatch_metric_alarm" "excessive_failed_logins" {
  alarm_name          = "${var.environment}-excessive-failed-logins"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedLoginAttempts"
  namespace           = "Security/Authentication"
  period              = 300  # 5 minutes
  statistic           = "Sum"
  threshold           = var.failed_login_threshold
  alarm_description   = "Alert on excessive failed login attempts"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]

  tags = var.tags
}

# Metric Filter: Privilege Escalation Attempts
resource "aws_cloudwatch_log_metric_filter" "privilege_escalation" {
  name           = "privilege-escalation-attempts"
  log_group_name = aws_cloudwatch_log_group.falco.name
  pattern        = "[... priority = CRITICAL*, ...]"

  metric_transformation {
    name      = "PrivilegeEscalationAttempts"
    namespace = "Security/Runtime"
    value     = "1"
  }
}

# Alarm: Privilege Escalation
resource "aws_cloudwatch_metric_alarm" "privilege_escalation" {
  alarm_name          = "${var.environment}-privilege-escalation"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "PrivilegeEscalationAttempts"
  namespace           = "Security/Runtime"
  period              = 60  # 1 minute
  statistic           = "Sum"
  threshold           = 0  # Alert on any occurrence
  alarm_description   = "Alert on privilege escalation attempts detected by Falco"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

# Metric Filter: Policy Violations
resource "aws_cloudwatch_log_metric_filter" "policy_violations" {
  name           = "kyverno-policy-violations"
  log_group_name = aws_cloudwatch_log_group.kyverno.name
  pattern        = "[... action = block*, ...]"

  metric_transformation {
    name      = "PolicyViolations"
    namespace = "Security/Compliance"
    value     = "1"
  }
}

# Alarm: High Policy Violations
resource "aws_cloudwatch_metric_alarm" "policy_violations" {
  alarm_name          = "${var.environment}-high-policy-violations"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "PolicyViolations"
  namespace           = "Security/Compliance"
  period              = 3600  # 1 hour
  statistic           = "Sum"
  threshold           = var.policy_violation_threshold
  alarm_description   = "Alert on high number of policy violations"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]

  tags = var.tags
}

# SNS Topic for Security Alerts
resource "aws_sns_topic" "security_alerts" {
  name              = "${var.environment}-security-alerts"
  kms_master_key_id = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name      = "security-alerts"
      Component = "security-audit"
    }
  )
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "security_alerts" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "security_team_email" {
  for_each = toset(var.security_team_emails)

  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# SNS Slack Subscription (via Lambda)
resource "aws_sns_topic_subscription" "slack" {
  count = var.slack_webhook_url != "" ? 1 : 0

  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier[0].arn
}

# Lambda for Slack Notifications
resource "aws_lambda_function" "slack_notifier" {
  count = var.slack_webhook_url != "" ? 1 : 0

  filename         = data.archive_file.slack_lambda[0].output_path
  function_name    = "${var.environment}-security-slack-notifier"
  role             = aws_iam_role.slack_lambda[0].arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.slack_lambda[0].output_base64sha256
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      ENVIRONMENT       = var.environment
    }
  }

  tags = var.tags
}

# Slack Lambda Code
resource "local_file" "slack_lambda_code" {
  count = var.slack_webhook_url != "" ? 1 : 0

  filename = "${path.module}/slack_notifier.py"
  content  = <<-EOF
import json
import urllib3
import os

http = urllib3.PoolManager()

def handler(event, context):
    slack_url = os.environ['SLACK_WEBHOOK_URL']
    environment = os.environ.get('ENVIRONMENT', 'unknown')

    # Parse SNS message
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])

    alarm_name = sns_message.get('AlarmName', 'Unknown')
    alarm_description = sns_message.get('AlarmDescription', '')
    new_state = sns_message.get('NewStateValue', 'UNKNOWN')
    reason = sns_message.get('NewStateReason', '')

    # Determine color based on state
    color = '#FF0000' if new_state == 'ALARM' else '#36A64F'

    # Build Slack message
    slack_message = {
        'username': 'Security Alert',
        'icon_emoji': ':warning:',
        'attachments': [{
            'color': color,
            'title': f'Security Alert: {alarm_name}',
            'text': alarm_description,
            'fields': [
                {'title': 'Environment', 'value': environment, 'short': True},
                {'title': 'State', 'value': new_state, 'short': True},
                {'title': 'Reason', 'value': reason, 'short': False}
            ],
            'footer': 'AWS CloudWatch',
            'ts': int(sns_message.get('StateChangeTime', 0))
        }]
    }

    # Send to Slack
    encoded_msg = json.dumps(slack_message).encode('utf-8')
    resp = http.request('POST', slack_url, body=encoded_msg)

    return {
        'statusCode': resp.status,
        'body': json.dumps('Message sent to Slack')
    }
EOF
}

data "archive_file" "slack_lambda" {
  count = var.slack_webhook_url != "" ? 1 : 0

  type        = "zip"
  source_file = local_file.slack_lambda_code[0].filename
  output_path = "${path.module}/slack_notifier.zip"

  depends_on = [local_file.slack_lambda_code]
}

# IAM Role for Slack Lambda
resource "aws_iam_role" "slack_lambda" {
  count = var.slack_webhook_url != "" ? 1 : 0

  name = "${var.environment}-slack-notifier-lambda"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "slack_lambda_basic" {
  count = var.slack_webhook_url != "" ? 1 : 0

  role       = aws_iam_role.slack_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "sns_to_slack_lambda" {
  count = var.slack_webhook_url != "" ? 1 : 0

  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.security_alerts.arn
}

# CloudWatch Dashboard for Security Metrics
resource "aws_cloudwatch_dashboard" "security" {
  dashboard_name = "${var.environment}-security-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["Security/Authentication", "FailedLoginAttempts"],
            ["Security/Runtime", "PrivilegeEscalationAttempts"],
            ["Security/Compliance", "PolicyViolations"]
          ]
          period = 300
          stat   = "Sum"
          region = local.region
          title  = "Security Events"
        }
      },
      {
        type = "log"
        properties = {
          query   = <<-QUERY
            SOURCE '${aws_cloudwatch_log_group.falco.name}'
            | fields @timestamp, priority, rule, output
            | filter priority in ["WARNING", "ERROR", "CRITICAL"]
            | sort @timestamp desc
            | limit 20
          QUERY
          region  = local.region
          title   = "Recent Falco Alerts"
        }
      },
      {
        type = "log"
        properties = {
          query   = <<-QUERY
            SOURCE '${aws_cloudwatch_log_group.kyverno.name}'
            | fields @timestamp, policy, resource, action
            | filter action = "block"
            | sort @timestamp desc
            | limit 20
          QUERY
          region  = local.region
          title   = "Policy Violations"
        }
      }
    ]
  })
}

output "security_events_log_group" {
  description = "CloudWatch Log Group for security events"
  value       = aws_cloudwatch_log_group.security_events.name
}

output "falco_log_group" {
  description = "CloudWatch Log Group for Falco events"
  value       = aws_cloudwatch_log_group.falco.name
}

output "kyverno_log_group" {
  description = "CloudWatch Log Group for Kyverno policy reports"
  value       = aws_cloudwatch_log_group.kyverno.name
}

output "sns_topic_arn" {
  description = "ARN of the security alerts SNS topic"
  value       = aws_sns_topic.security_alerts.arn
}

output "dashboard_url" {
  description = "URL to the CloudWatch security dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${local.region}#dashboards:name=${aws_cloudwatch_dashboard.security.dashboard_name}"
}
