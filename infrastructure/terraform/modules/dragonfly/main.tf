locals {
  redis_endpoint = "redis.${var.region}.${var.environment}.voxguard.internal:6379"

  connection_endpoints = {
    primary  = local.redis_endpoint
    read     = local.redis_endpoint
    replicas = var.replica_regions
  }
}
