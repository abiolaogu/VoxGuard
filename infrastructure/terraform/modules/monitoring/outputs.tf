output "prometheus_endpoint" {
  description = "Prometheus endpoint"
  value       = local.prometheus_endpoint
}

output "grafana_endpoint" {
  description = "Grafana endpoint"
  value       = local.grafana_endpoint
}
