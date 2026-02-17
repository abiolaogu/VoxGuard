output "redis_endpoint" {
  description = "Dragonfly Redis endpoint"
  value       = local.redis_endpoint
}

output "connection_endpoints" {
  description = "Dragonfly connection endpoints"
  value       = local.connection_endpoints
}
