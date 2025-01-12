resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
    
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      environment                    = var.environment
    }
  }
}

# ArgoCD installation via Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    yamlencode({
      global = {
        image = {
          tag = var.argocd_version
        }
      }
      configs = {
        repositories = {
          # Configure known hosts for SSH connections
          knownHosts = <<-EOT
            github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
            gitlab.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9
            bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==
          EOT
        }
        credentialTemplates = {}  # Will be populated by credentials
      }
      repoServer = {
        volumes = [
          {
            name = "custom-tools"
            emptyDir = {}
          }
        ]
        volumeMounts = [
          {
            name      = "custom-tools"
            mountPath = "/usr/local/bin/custom-tools"
          }
        ]
        initContainers = [
          {
            name  = "download-tools"
            image = "alpine:3.14"
            command = [
              "sh",
              "-c",
              "apk add --no-cache git openssh curl"
            ]
            volumeMounts = [
              {
                name      = "custom-tools"
                mountPath = "/usr/local/bin/custom-tools"
              }
            ]
          }
        ]
      }
    })
  ]
}

# IAM role for ArgoCD
resource "aws_iam_role" "argocd" {
  name = "argocd-${var.environment}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:argocd-repo-server"
          }
        }
      }
    ]
  })
}

# IAM policy for S3/ECR access
resource "aws_iam_role_policy" "argocd" {
  name = "argocd-${var.environment}-policy"
  role = aws_iam_role.argocd.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::*"
        ]
      }
    ]
  })
}

# ArgoCD Git repositories
resource "kubernetes_manifest" "git_repository" {
  for_each = { for repo in var.git_repositories : repo.name => repo }

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Repository"
    metadata = {
      name      = each.value.name
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      url = each.value.url
      path = each.value.path
      type = "git"
    }
  }

  depends_on = [
    helm_release.argocd
  ]
}

resource "kubernetes_manifest" "argocd_servicemonitor" {
  count = var.enable_monitoring ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "argocd-metrics"
      namespace = kubernetes_namespace.argocd.metadata[0].name
      labels = {
        "app.kubernetes.io/component" = "metrics"
        "app.kubernetes.io/name"      = "argocd"
        "release"                     = "prometheus"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "argocd-metrics"
        }
      }
      endpoints = [
        {
          port = "metrics"
          path = "/metrics"
        }
      ]
    }
  }

  depends_on = [
    helm_release.argocd
  ]
}

# PrometheusRule for ArgoCD alerts
resource "kubernetes_manifest" "argocd_prometheusrule" {
  count = var.enable_monitoring ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "argocd-alerts"
      namespace = kubernetes_namespace.argocd.metadata[0].name
      labels = {
        "app.kubernetes.io/name" = "argocd"
        "prometheus"             = "true"
      }
    }
    spec = {
      groups = [
        {
          name = "argocd.rules"
          rules = [
            {
              alert = "ArgoCDSyncFailed"
              expr  = "argocd_app_sync_status{sync_status=\"OutOfSync\"} == 1"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Application {{ $labels.name }} is out of sync"
                description = "ArgoCD application {{ $labels.name }} has been out of sync for more than 5 minutes."
              }
            },
            {
              alert = "ArgoCDAppHealthDegraded"
              expr  = "argocd_app_health_status{health_status=\"Degraded\"} == 1"
              for   = "5m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "Application {{ $labels.name }} is degraded"
                description = "ArgoCD application {{ $labels.name }} has been in a degraded state for more than 5 minutes."
              }
            },
            {
              alert = "ArgoCDHighReconciliation"
              expr  = "rate(argocd_app_reconcile_count[5m]) > 5"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High reconciliation rate for {{ $labels.name }}"
                description = "ArgoCD application {{ $labels.name }} has a high reconciliation rate."
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    helm_release.argocd
  ]
}

# Grafana Dashboard ConfigMap
resource "kubernetes_config_map" "argocd_dashboard" {
  count = var.enable_monitoring ? 1 : 0

  metadata {
    name      = "argocd-dashboard"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      grafana_dashboard = "true"
    }
  }

  data = {
    "argocd-dashboard.json" = file("${path.module}/dashboards/argocd-dashboard.json")
  }
}

# AlertManager configuration for notifications
resource "kubernetes_secret" "alertmanager_config" {
  count = var.enable_monitoring && (var.alert_slack_webhook != "" || var.alert_email_to != "") ? 1 : 0

  metadata {
    name      = "alertmanager-argocd"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  data = {
    "alertmanager.yaml" = yamlencode({
      global = {
        resolve_timeout = "5m"
      }
      route = {
        group_by = ["job", "severity"]
        group_wait      = "30s"
        group_interval  = "5m"
        repeat_interval = "12h"
        receiver        = "argocd-notifications"
      }
      receivers = concat(
        var.alert_slack_webhook != "" ? [{
          name = "argocd-notifications"
          slack_configs = [{
            api_url = var.alert_slack_webhook
            channel = "#argocd-alerts"
            title   = "{{ .GroupLabels.job }} {{ .Status | toUpper}}{{ if eq .Status \"firing\" }} ({{ .Alerts.Firing | len }}){{ end }}"
            text    = "{{ range .Alerts }}*Alert:* {{ .Annotations.summary }}\n*Description:* {{ .Annotations.description }}\n*Severity:* {{ .Labels.severity }}\n{{ end }}"
          }]
        }] : [],
        var.alert_email_to != "" ? [{
          name = "argocd-notifications"
          email_configs = [{
            to = var.alert_email_to
            from = "argocd-alerts@${var.environment}.local"
            smarthost = "smtp.example.com:587"
            require_tls = true
          }]
        }] : []
      )
    })
  }
}

resource "kubernetes_secret" "repo_credentials" {
  for_each = {
    for repo in var.repositories : repo.name => repo
    if repo.credentials != null
  }

  metadata {
    name      = "repo-${each.key}"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    url = each.value.url
    type = each.value.type
    insecure = each.value.insecure ? "true" : "false"
    # Add credentials based on what's provided
    username = try(each.value.credentials.username, null) != null ? each.value.credentials.username : null
    password = try(each.value.credentials.password, null) != null ? each.value.credentials.password : null
    sshPrivateKey = try(each.value.credentials.ssh_private_key, null) != null ? each.value.credentials.ssh_private_key : null
    tlsClientCert = try(each.value.credentials.tls_client_cert, null) != null ? each.value.credentials.tls_client_cert : null
    tlsClientCertKey = try(each.value.credentials.tls_client_cert_key, null) != null ? each.value.credentials.tls_client_cert_key : null
  }
}

# Secret for GitHub App credentials
resource "kubernetes_secret" "github_app_credentials" {
  for_each = {
    for app in var.github_apps : app.id => app
  }

  metadata {
    name      = "github-app-${each.key}"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "github-app"
    }
  }

  data = {
    id              = each.value.id
    installationID  = each.value.installation_id
    privateKey      = each.value.private_key
  }
}

# Secret for repository certificates
resource "kubernetes_secret" "repo_certs" {
  for_each = {
    for cert in var.repositories_cert : cert.server_name => cert
  }

  metadata {
    name      = "repo-cert-${each.key}"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository-certificates"
    }
  }

  data = {
    "cert-${each.key}" = each.value.cert_data
  }
}