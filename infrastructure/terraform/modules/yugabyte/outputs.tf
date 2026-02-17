output "ysql_endpoint" {
  description = "YSQL endpoint"
  value       = local.ysql_endpoint
}

output "ycql_endpoint" {
  description = "YCQL endpoint"
  value       = local.ycql_endpoint
}

output "connection_endpoints" {
  description = "Yugabyte connection endpoints"
  value       = local.connection_endpoints
}
