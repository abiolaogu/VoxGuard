locals {
  ysql_endpoint = "yugabyte-ysql.${var.region}.${var.environment}.voxguard.internal:5433"
  ycql_endpoint = "yugabyte-ycql.${var.region}.${var.environment}.voxguard.internal:9042"

  connection_endpoints = {
    ysql    = local.ysql_endpoint
    ycql    = local.ycql_endpoint
    masters = [for i in range(var.master_replicas) : "yb-master-${i + 1}.${var.region}.${var.environment}.voxguard.internal:7100"]
  }
}
