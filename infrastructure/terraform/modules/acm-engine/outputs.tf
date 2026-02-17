output "http_endpoint" {
  description = "ACM engine HTTP endpoint"
  value       = local.http_endpoint
}

output "grpc_endpoint" {
  description = "ACM engine gRPC endpoint"
  value       = local.grpc_endpoint
}
