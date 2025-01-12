output "istiod_version" {
  description = "Installed version of Istiod"
  value       = var.chart_version
}

output "gateway_service_name" {
  description = "Service name of the Ingress Gateway"
  value       = var.install_ingress_gateway ? "${helm_release.ingress_gateway[0].name}-${helm_release.ingress_gateway[0].chart}" : ""
}

output "gateway_namespace" {
  description = "Namespace of the Ingress Gateway"
  value       = var.gateway_namespace
}

output "default_gateway_name" {
  description = "Name of the default Gateway resource"
  value       = var.create_default_gateway ? kubectl_manifest.default_gateway[0].name : ""
}
