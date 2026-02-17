locals {
  prometheus_endpoint = "https://prometheus.${var.region}.${var.environment}.voxguard.internal"
  grafana_endpoint    = var.enable_grafana ? "https://grafana.${var.region}.${var.environment}.voxguard.internal" : null
}
