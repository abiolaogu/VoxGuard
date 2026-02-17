locals {
  http_endpoint = "https://acm-engine.${var.region}.${var.environment}.voxguard.internal"
  grpc_endpoint = "acm-engine.${var.region}.${var.environment}.voxguard.internal:50051"
}
