output "operator_namespace" {
  description = "Namespace where Jaeger operator is installed"
  value       = var.operator_namespace
}

output "jaeger_namespace" {
  description = "Namespace where Jaeger instance is installed"
  value       = var.jaeger_namespace
}

output "jaeger_query_service" {
  description = "Name of the Jaeger query service"
  value       = var.create_jaeger_instance ? "${var.jaeger_name}-query" : ""
}

output "jaeger_collector_service" {
  description = "Name of the Jaeger collector service"
  value       = var.create_jaeger_instance ? "${var.jaeger_name}-collector" : ""
}

output "otel_collector_service" {
  description = "Name of the OpenTelemetry collector service"
  value       = var.install_otel_collector ? "${var.jaeger_name}-otel-collector" : ""
}