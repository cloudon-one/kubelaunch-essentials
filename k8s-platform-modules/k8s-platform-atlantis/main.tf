locals {
  name      = var.name
  namespace = var.namespace
}

data "aws_region" "current" {}

resource "kubernetes_namespace" "atlantis" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = local.namespace
    labels = merge(
      var.namespace_labels,
      {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    )
  }
}

resource "kubernetes_secret" "atlantis_secrets" {
  metadata {
    name      = "${local.name}-secrets"
    namespace = local.namespace
  }

  data = {
    ATLANTIS_GH_TOKEN               = var.github_token
    ATLANTIS_GH_WEBHOOK_SECRET      = var.github_webhook_secret
    ATLANTIS_GITLAB_TOKEN           = var.gitlab_token
    ATLANTIS_GITLAB_WEBHOOK_SECRET  = var.gitlab_webhook_secret
    AWS_ACCESS_KEY_ID               = var.aws_access_key
    AWS_SECRET_ACCESS_KEY           = var.aws_secret_key
    ATLANTIS_REPO_CONFIG            = var.repo_config_json
  }

  depends_on = [kubernetes_namespace.atlantis]
}

resource "kubernetes_service_account" "atlantis" {
  metadata {
    name      = "${local.name}-sa"
    namespace = local.namespace
    annotations = merge(
      {
        "eks.amazonaws.com/role-arn" = var.iam_role_arn
      },
      var.service_account_annotations
    )
  }

  depends_on = [kubernetes_namespace.atlantis]
}

resource "helm_release" "atlantis" {
  name       = local.name
  repository = "https://runatlantis.github.io/helm-charts"
  chart      = "atlantis"
  version    = var.chart_version
  namespace  = local.namespace

  values = [
    <<-EOT
    image:
      tag: "${var.image_tag}"

    serviceAccount:
      create: true
      name: "${kubernetes_service_account.atlantis.metadata[0].name}"

    resources:
      ${yamlencode(var.resources)}

    orgWhitelist: "${join(",", var.org_whitelist)}"

    atlantisUrl: "${var.webhook_url}"

    vcsSecret:
      github:
        token: "$ATLANTIS_GH_TOKEN"
        webhookSecret: "$ATLANTIS_GH_WEBHOOK_SECRET"
      gitlab:
        token: "$ATLANTIS_GITLAB_TOKEN"
        webhookSecret: "$ATLANTIS_GITLAB_WEBHOOK_SECRET"

    aws:
      region: "${data.aws_region.current.name}"
      credentials:
        secretName: "${local.name}-secrets"
        accessKey: "AWS_ACCESS_KEY_ID"
        secretKey: "AWS_SECRET_ACCESS_KEY"

    repoConfig: "$ATLANTIS_REPO_CONFIG"

    dataStorage:
      enabled: true
      storageClass: "${var.storage_class}"
      size: "${var.storage_size}"

    ingress:
      enabled: ${var.ingress_enabled}
      %{if var.ingress_enabled}
      annotations:
        ${yamlencode(var.ingress_annotations)}
      hosts:
        - host: ${var.ingress_host}
          paths:
            - path: /
              pathType: Prefix
      %{endif}
    EOT
  ]

  depends_on = [
    kubernetes_namespace.atlantis,
    kubernetes_service_account.atlantis,
    kubernetes_secret.atlantis_secrets
  ]
}