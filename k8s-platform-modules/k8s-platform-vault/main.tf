data "aws_region" "current" {}
locals {
  namespace = var.namespace == "" ? "vault" : var.namespace
  name      = var.name
  
  default_helm_values = {
    server = {
      ha = {
        enabled = true
        replicas = var.replicas
      }
      
      extraLabels = merge(
        var.extra_labels,
        {
          "app.kubernetes.io/managed-by" = "terraform"
        }
      )
      
      dataStorage = {
        enabled = true
        size     = var.storage_size
        storageClass = var.storage_class
      }
      
      extraEnvironmentVars = {
        "VAULT_CACERT"        = "/vault/userconfig/tls-ca/ca.crt"
        "VAULT_SKIP_VERIFY"   = "false"
        "VAULT_ADDR"          = "https://127.0.0.1:8200"
        "VAULT_API_ADDR"      = "https://$(POD_IP):8200"
        "VAULT_CLUSTER_ADDR"  = "https://$(POD_IP):8201"
      }
      
      auditStorage = {
        enabled = true
        size    = var.audit_storage_size
        storageClass = var.storage_class
      }

      serviceAccount = {
        create = true
        annotations = var.service_account_annotations
      }
    }

    ui = {
      enabled = true
      serviceType = "ClusterIP"
    }
  }
}

resource "kubernetes_namespace" "vault" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = local.namespace
    
    labels = merge(
      var.namespace_labels,
      {
        name = local.namespace
      }
    )
  }
}

# Create service account
resource "kubernetes_service_account" "vault" {
  metadata {
    name      = "${local.name}-sa"
    namespace = local.namespace
    annotations = merge(
      {
        "eks.amazonaws.com/role-arn" = var.iam_role_arn
      },
      var.service_account_annotations
    )
    labels = {
      "app.kubernetes.io/name"       = local.name
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  depends_on = [kubernetes_namespace.vault]
}

resource "helm_release" "vault" {
  name       = local.name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = var.chart_version
  namespace  = local.namespace

  values = [
    templatefile("${path.module}/templates/values.yaml", {
      replicas              = var.replicas
      aws_region            = data.aws_region.current.name
      kms_key_id            = var.kms_key_id
      storage_class         = var.storage_class
      storage_size          = var.storage_size
      audit_storage_size    = var.audit_storage_size
      service_account_name  = kubernetes_service_account.vault.metadata[0].name
      iam_role_arn          = var.iam_role_arn
      node_selector_key     = var.node_selector_key
      node_selector_value   = var.node_selector_value
      ingress_enabled       = var.ingress_enabled
      ingress_host          = var.ingress_host
      ingress_annotations   = var.ingress_annotations
      resources             = var.resources
      ui_enabled            = var.ui_enabled
      injector_enabled      = var.injector_enabled
      csi_enabled           = var.csi_enabled
    })
  ]

  depends_on = [
    kubernetes_namespace.vault,
    kubernetes_service_account.vault
  ]
}