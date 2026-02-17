# VoxGuard Multi-Region Deployment
# Terraform Configuration for Lagos (Primary), Abuja (Replica), Asaba (Replica)
#
# This configuration deploys VoxGuard across three Nigerian regions:
# - Lagos: Primary data center with 3 OpenSIPS instances
# - Abuja: Replica with 1 OpenSIPS instance + read replicas
# - Asaba: Replica with 1 OpenSIPS instance + read replicas

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote backend with DynamoDB state locking.
  # Use `terraform init -backend-config=backend.hcl` where backend.hcl
  # provides bucket/key/region/dynamodb_table values per environment.
  backend "s3" {}
}

# Local variables
locals {
  project_name = "voxguard"
  environment  = var.environment

  # Common tags for all resources
  common_tags = {
    Project     = "VoxGuard"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "https://github.com/abiolaogu/VoxGuard"
  }

  # Region configuration
  regions = {
    lagos = {
      name               = "lagos"
      is_primary         = true
      opensips_replicas  = 3
      acm_replicas       = 4
      availability_zones = ["lagos-az1", "lagos-az2", "lagos-az3"]
    }
    abuja = {
      name               = "abuja"
      is_primary         = false
      opensips_replicas  = 1
      acm_replicas       = 2
      availability_zones = ["abuja-az1", "abuja-az2"]
    }
    asaba = {
      name               = "asaba"
      is_primary         = false
      opensips_replicas  = 1
      acm_replicas       = 2
      availability_zones = ["asaba-az1", "asaba-az2"]
    }
  }
}

# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# Module: Network Infrastructure
module "network" {
  source = "./modules/network"

  for_each = local.regions

  project_name = local.project_name
  environment  = var.environment
  region       = each.value.name

  vpc_cidr = var.vpc_cidrs[each.value.name]
  azs      = each.value.availability_zones

  # Enable VPN mesh between regions
  enable_vpn_mesh = true
  peer_regions    = [for k, v in local.regions : k if k != each.value.name]

  tags = local.common_tags
}

# Module: DragonflyDB (Cache and State Store)
module "dragonfly" {
  source = "./modules/dragonfly"

  for_each = local.regions

  project_name = local.project_name
  environment  = var.environment
  region       = each.value.name
  is_primary   = each.value.is_primary

  # Replication configuration
  enable_replication = true
  primary_region     = "lagos"
  replica_regions    = each.value.is_primary ? ["abuja", "asaba"] : []

  # Resource allocation
  memory_limit_gb = each.value.is_primary ? 16 : 8
  cpu_cores       = each.value.is_primary ? 8 : 4

  # High availability
  replicas = each.value.is_primary ? 3 : 1

  # Network dependencies
  vpc_id     = module.network[each.key].vpc_id
  subnet_ids = module.network[each.key].private_subnet_ids

  tags = local.common_tags

  depends_on = [module.network]
}

# Module: YugabyteDB (Distributed SQL Database)
module "yugabyte" {
  source = "./modules/yugabyte"

  for_each = local.regions

  project_name = local.project_name
  environment  = var.environment
  region       = each.value.name
  is_primary   = each.value.is_primary

  # Multi-region configuration
  enable_geo_distribution = true
  replication_factor      = 3
  placement_zones         = each.value.availability_zones

  # Leader preference for writes
  preferred_leaders = each.value.is_primary ? [each.value.name] : ["lagos"]

  # Resource allocation
  tserver_cpu_cores    = each.value.is_primary ? 8 : 4
  tserver_memory_gb    = each.value.is_primary ? 16 : 8
  master_cpu_cores     = 4
  master_memory_gb     = 8

  # Storage
  disk_size_gb = each.value.is_primary ? 500 : 250
  disk_type    = "ssd"

  # High availability
  tserver_replicas = each.value.is_primary ? 3 : 1
  master_replicas  = each.value.is_primary ? 3 : 1

  # Network dependencies
  vpc_id     = module.network[each.key].vpc_id
  subnet_ids = module.network[each.key].private_subnet_ids

  tags = local.common_tags

  depends_on = [module.network]
}

# Module: OpenSIPS (Voice Switch)
module "opensips" {
  source = "./modules/opensips"

  for_each = local.regions

  project_name = local.project_name
  environment  = var.environment
  region       = each.value.name
  is_primary   = each.value.is_primary

  # Scaling configuration
  replicas     = each.value.opensips_replicas
  min_replicas = each.value.opensips_replicas
  max_replicas = each.value.is_primary ? 10 : 5

  # Resource allocation
  cpu_request    = "2000m"
  cpu_limit      = "4000m"
  memory_request = "2Gi"
  memory_limit   = "4Gi"

  # Configuration
  workers                = 32
  max_tcp_connections    = 8192
  circuit_breaker_config = var.circuit_breaker_config

  # Database connections
  yugabyte_endpoints    = module.yugabyte[each.key].connection_endpoints
  dragonfly_endpoints   = module.dragonfly[each.key].connection_endpoints

  # Network dependencies
  vpc_id     = module.network[each.key].vpc_id
  subnet_ids = module.network[each.key].private_subnet_ids

  # Load balancer
  enable_load_balancer = true
  lb_type              = each.value.is_primary ? "external" : "internal"

  tags = local.common_tags

  depends_on = [module.yugabyte, module.dragonfly]
}

# Module: ACM Detection Engine
module "acm_engine" {
  source = "./modules/acm-engine"

  for_each = local.regions

  project_name = local.project_name
  environment  = var.environment
  region       = each.value.name
  is_primary   = each.value.is_primary

  # Scaling configuration
  replicas     = each.value.acm_replicas
  min_replicas = each.value.acm_replicas
  max_replicas = each.value.is_primary ? 10 : 5

  # Resource allocation
  cpu_request    = "2000m"
  cpu_limit      = "4000m"
  memory_request = "2Gi"
  memory_limit   = "4Gi"

  # Database connections
  yugabyte_endpoints  = module.yugabyte[each.key].connection_endpoints
  dragonfly_endpoints = module.dragonfly[each.key].connection_endpoints

  # Network dependencies
  vpc_id     = module.network[each.key].vpc_id
  subnet_ids = module.network[each.key].private_subnet_ids

  tags = local.common_tags

  depends_on = [module.yugabyte, module.dragonfly]
}

# Module: Regional Load Balancer
module "regional_lb" {
  source = "./modules/regional-lb"

  project_name = local.project_name
  environment  = var.environment

  # Define regions and their endpoints
  regions = {
    for k, v in local.regions : k => {
      opensips_endpoints = module.opensips[k].service_endpoints
      weight             = v.is_primary ? 70 : 15  # 70% Lagos, 15% Abuja, 15% Asaba
      is_primary         = v.is_primary
    }
  }

  # Health check configuration
  health_check_interval = "10s"
  health_check_timeout  = "5s"
  health_check_path     = "/health"

  # Session affinity for SIP dialogs
  enable_session_affinity = true
  session_affinity_ttl    = "1800s"  # 30 minutes

  # Circuit breaker
  enable_circuit_breaker      = true
  circuit_breaker_threshold   = 5
  circuit_breaker_timeout     = "30s"

  tags = local.common_tags

  depends_on = [module.opensips]
}

# Module: Monitoring Stack
module "monitoring" {
  source = "./modules/monitoring"

  for_each = local.regions

  project_name = local.project_name
  environment  = var.environment
  region       = each.value.name
  is_primary   = each.value.is_primary

  # Prometheus configuration
  enable_prometheus         = true
  prometheus_retention_days = 30
  prometheus_storage_gb     = each.value.is_primary ? 100 : 50

  # Grafana configuration (only in primary)
  enable_grafana = each.value.is_primary
  grafana_admin_password = var.grafana_admin_password

  # Tempo tracing (only in primary)
  enable_tempo         = each.value.is_primary
  tempo_retention_days = 7
  tempo_storage_gb     = 50

  # Network dependencies
  vpc_id     = module.network[each.key].vpc_id
  subnet_ids = module.network[each.key].private_subnet_ids

  tags = local.common_tags

  depends_on = [module.network]
}

# Outputs
output "regional_endpoints" {
  description = "Regional service endpoints"
  value = {
    for k, v in module.opensips : k => {
      opensips_sip_endpoint = v.sip_endpoint
      opensips_mi_endpoint  = v.management_endpoint
      region                = v.region
      is_primary            = v.is_primary
    }
  }
}

output "database_endpoints" {
  description = "Database connection endpoints"
  value = {
    yugabyte = {
      for k, v in module.yugabyte : k => {
        ysql_endpoint = v.ysql_endpoint
        ycql_endpoint = v.ycql_endpoint
      }
    }
    dragonfly = {
      for k, v in module.dragonfly : k => v.redis_endpoint
    }
  }
  sensitive = true
}

output "load_balancer_endpoint" {
  description = "Global load balancer endpoint"
  value       = module.regional_lb.global_endpoint
}

output "monitoring_endpoints" {
  description = "Monitoring stack endpoints"
  value = {
    grafana    = try(module.monitoring["lagos"].grafana_endpoint, null)
    prometheus = {
      for k, v in module.monitoring : k => v.prometheus_endpoint
    }
  }
}
