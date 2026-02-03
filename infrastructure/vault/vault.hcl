# HashiCorp Vault Configuration for VoxGuard
# This configuration sets up Vault for production deployment

# Storage backend - PostgreSQL for production (can also use Consul, Raft, etc.)
storage "postgresql" {
  connection_url = "postgres://vault:VAULT_DB_PASSWORD@yugabyte:5433/vault_db?sslmode=require"
  ha_enabled     = "true"
  max_parallel   = "128"
}

# HA Storage using Consul (optional, recommended for production)
# storage "consul" {
#   address = "consul:8500"
#   path    = "vault/"
# }

# TCP Listener
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = "false"
  tls_cert_file = "/vault/config/tls/vault.crt"
  tls_key_file  = "/vault/config/tls/vault.key"

  # Client certificate authentication (optional)
  tls_require_and_verify_client_cert = "false"

  # TLS configuration
  tls_min_version = "tls13"
  tls_cipher_suites = [
    "TLS_AES_256_GCM_SHA384",
    "TLS_CHACHA20_POLY1305_SHA256",
    "TLS_AES_128_GCM_SHA256"
  ]
}

# API address for high availability
api_addr = "https://vault:8200"
cluster_addr = "https://vault:8201"

# UI
ui = true

# Telemetry
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = false
  unauthenticated_metrics_access = false
}

# Seal configuration - Auto-unseal with cloud KMS (recommended for production)
# For AWS KMS
# seal "awskms" {
#   region     = "us-east-1"
#   kms_key_id = "arn:aws:kms:us-east-1:XXXXXXXXXXXX:key/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
# }

# For Azure Key Vault
# seal "azurekeyvault" {
#   tenant_id     = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
#   client_id     = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
#   client_secret = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
#   vault_name    = "voxguard-vault"
#   key_name      = "vault-seal-key"
# }

# For development: Shamir seal (default, requires manual unseal)
seal "shamir" {
  # No configuration needed
}

# Disable mlock for containers (in production with mlock capability, set to false)
disable_mlock = true

# Log level
log_level = "info"

# Cluster name
cluster_name = "voxguard-vault-cluster"

# Maximum request duration
max_lease_ttl = "768h"
default_lease_ttl = "168h"

# Plugin directory
plugin_directory = "/vault/plugins"
