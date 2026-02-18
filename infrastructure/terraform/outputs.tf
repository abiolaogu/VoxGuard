# VoxGuard Multi-Region Deployment Outputs

output "deployment_summary" {
  description = "Summary of multi-region deployment"
  value = {
    environment     = var.environment
    regions         = ["lagos", "abuja", "asaba"]
    primary_region  = "lagos"
    total_opensips  = 5  # 3 Lagos + 1 Abuja + 1 Asaba
    total_acm       = 8  # 4 Lagos + 2 Abuja + 2 Asaba
  }
}

output "connection_strings" {
  description = "Connection strings for services"
  value = {
    global_sip_endpoint = module.regional_lb.global_endpoint
    lagos_endpoints = {
      sip       = module.opensips["lagos"].sip_endpoint
      management = module.opensips["lagos"].management_endpoint
      yugabyte  = module.yugabyte["lagos"].ysql_endpoint
      dragonfly = module.dragonfly["lagos"].redis_endpoint
    }
    abuja_endpoints = {
      sip       = module.opensips["abuja"].sip_endpoint
      management = module.opensips["abuja"].management_endpoint
      yugabyte  = module.yugabyte["abuja"].ysql_endpoint
      dragonfly = module.dragonfly["abuja"].redis_endpoint
    }
    asaba_endpoints = {
      sip       = module.opensips["asaba"].sip_endpoint
      management = module.opensips["asaba"].management_endpoint
      yugabyte  = module.yugabyte["asaba"].ysql_endpoint
      dragonfly = module.dragonfly["asaba"].redis_endpoint
    }
  }
  sensitive = true
}

output "monitoring_urls" {
  description = "Monitoring dashboard URLs"
  value = {
    grafana    = try(module.monitoring["lagos"].grafana_endpoint, "Not deployed")
    prometheus_lagos = module.monitoring["lagos"].prometheus_endpoint
    prometheus_abuja = module.monitoring["abuja"].prometheus_endpoint
    prometheus_asaba = module.monitoring["asaba"].prometheus_endpoint
  }
}

output "health_check_endpoints" {
  description = "Health check endpoints for each region"
  value = {
    for region in ["lagos", "abuja", "asaba"] : region => {
      opensips = "${module.opensips[region].sip_endpoint}/health"
      yugabyte = "${module.yugabyte[region].ysql_endpoint}/health"
      dragonfly = "${module.dragonfly[region].redis_endpoint}/health"
    }
  }
}

output "replication_status" {
  description = "Database replication status"
  value = {
    dragonfly = {
      primary = "lagos"
      replicas = ["abuja", "asaba"]
      replication_lag_threshold_ms = 100
    }
    yugabyte = {
      mode = "geo-distributed"
      replication_factor = 3
      preferred_leaders = ["lagos"]
      read_replicas = ["abuja", "asaba"]
    }
  }
}

output "terraform_state_info" {
  description = "Information about Terraform state management"
  value = {
    backend        = "s3"
    recommendation = "Initialize with backend.hcl to set bucket/key/region and DynamoDB lock table"
    state_locking  = true
  }
}

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
    1. Verify regional connectivity:
       - kubectl get nodes --all-namespaces
       - Test VPN mesh: ping between regions

    2. Check database replication:
       - DragonflyDB: redis-cli -h <primary> INFO replication
       - YugabyteDB: ysqlsh -h <master> -c "SELECT * FROM yb_servers()"

    3. Validate OpenSIPS load balancing:
       - curl http://<regional-lb>/stats
       - Check HAProxy dashboard at port 8404

    4. Test failover scenarios:
       - Simulate Lagos failure
       - Verify Abuja/Asaba take over traffic

    5. Configure monitoring:
       - Access Grafana at ${try(module.monitoring["lagos"].grafana_endpoint, "Not deployed")}
       - Import multi-region dashboards
       - Set up alert rules for replication lag

    6. Run load tests:
       - Use SIPp to test 500+ CPS
       - Monitor latency across regions
       - Verify circuit breaker behavior

    7. Security hardening:
       - Enable network policies: kubectl apply -f network-policies/
       - Configure TLS certificates
       - Review IAM roles and permissions
  EOT
}
