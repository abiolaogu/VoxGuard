#!/bin/sh
# Vault Initialization Script for VoxGuard
# This script initializes Vault, unseals it, and sets up initial configuration

set -e

echo "Waiting for Vault to be ready..."
sleep 10

# Check if Vault is already initialized
if vault status 2>&1 | grep -q "Initialized.*true"; then
    echo "Vault is already initialized"
    exit 0
fi

echo "Initializing Vault..."

# Initialize Vault with 5 key shares and 3 key threshold
vault operator init -key-shares=5 -key-threshold=3 -format=json > /vault/keys/init-keys.json

echo "Vault initialized successfully!"

# Extract unseal keys and root token
UNSEAL_KEY_1=$(cat /vault/keys/init-keys.json | jq -r '.unseal_keys_b64[0]')
UNSEAL_KEY_2=$(cat /vault/keys/init-keys.json | jq -r '.unseal_keys_b64[1]')
UNSEAL_KEY_3=$(cat /vault/keys/init-keys.json | jq -r '.unseal_keys_b64[2]')
ROOT_TOKEN=$(cat /vault/keys/init-keys.json | jq -r '.root_token')

echo "Unsealing Vault..."
vault operator unseal $UNSEAL_KEY_1
vault operator unseal $UNSEAL_KEY_2
vault operator unseal $UNSEAL_KEY_3

echo "Vault unsealed successfully!"

# Login with root token
vault login $ROOT_TOKEN

echo "Configuring Vault..."

# Enable KV v2 secrets engine at 'secret/'
vault secrets enable -path=secret -version=2 kv || echo "KV secrets engine already enabled"

# Enable Transit secrets engine for encryption
vault secrets enable transit || echo "Transit engine already enabled"

# Create encryption key for VoxGuard
vault write -f transit/keys/voxguard-data || echo "Transit key already exists"
vault write -f transit/keys/voxguard-jwt type=rsa-2048 || echo "JWT key already exists"

# Enable database secrets engine
vault secrets enable database || echo "Database engine already enabled"

# Configure PostgreSQL database connection (adjust credentials as needed)
vault write database/config/yugabyte \
    plugin_name=postgresql-database-plugin \
    allowed_roles="voxguard-app" \
    connection_url="postgresql://{{username}}:{{password}}@yugabyte:5433/acm_db?sslmode=prefer" \
    username="vault_admin" \
    password="CHANGE_ME" || echo "Database config already exists"

# Create database role for dynamic credentials
vault write database/roles/voxguard-app \
    db_name=yugabyte \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; \
        GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h" || echo "Database role already exists"

# Create policy for VoxGuard application
vault policy write voxguard-app - <<EOF
# Allow reading JWT signing keys
path "secret/data/jwt/*" {
  capabilities = ["read"]
}

# Allow reading NCC credentials
path "secret/data/ncc/*" {
  capabilities = ["read"]
}

# Allow reading database credentials
path "database/creds/voxguard-app" {
  capabilities = ["read"]
}

# Allow using transit engine
path "transit/encrypt/voxguard-*" {
  capabilities = ["update"]
}

path "transit/decrypt/voxguard-*" {
  capabilities = ["update"]
}

path "transit/keys/voxguard-*" {
  capabilities = ["read"]
}

path "transit/sign/voxguard-jwt" {
  capabilities = ["update"]
}

# Token operations
path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

echo "Policy created successfully!"

# Create a token for the application with the policy
APP_TOKEN=$(vault token create -policy=voxguard-app -ttl=720h -format=json | jq -r '.auth.client_token')

echo "Application token created: $APP_TOKEN"
echo $APP_TOKEN > /vault/keys/app-token.txt

# Generate and store initial JWT signing keys
echo "Generating JWT signing keys..."

# For development, we'll store keys in Vault's KV store
# In production, use Transit engine for key management

# Note: In a real deployment, generate proper RSA keys
# This is a placeholder - actual key generation should be done properly
vault kv put secret/jwt/signing-key \
    private_key="PLACEHOLDER_PRIVATE_KEY" \
    public_key="PLACEHOLDER_PUBLIC_KEY" \
    created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)" || echo "JWT keys already exist"

# Store NCC credentials (placeholder - replace with actual credentials)
vault kv put secret/ncc/credentials \
    client_id="PLACEHOLDER_CLIENT_ID" \
    client_secret="PLACEHOLDER_CLIENT_SECRET" \
    api_base_url="https://atrs-api.ncc.gov.ng/v1" \
    sftp_host="sftp.ncc.gov.ng" \
    sftp_user="voxguard" \
    sftp_private_key="PLACEHOLDER_SSH_KEY" || echo "NCC credentials already exist"

echo ""
echo "=========================================="
echo "Vault Setup Complete!"
echo "=========================================="
echo ""
echo "IMPORTANT: Save these credentials securely!"
echo ""
echo "Root Token: $ROOT_TOKEN"
echo "App Token: $APP_TOKEN"
echo ""
echo "Unseal keys are stored in: /vault/keys/init-keys.json"
echo "App token is stored in: /vault/keys/app-token.txt"
echo ""
echo "⚠️  In production:"
echo "  1. Store unseal keys in separate secure locations"
echo "  2. Revoke the root token after initial setup"
echo "  3. Use AppRole or Kubernetes auth instead of static tokens"
echo "  4. Enable auto-unseal with cloud KMS"
echo "  5. Generate proper RSA keys for JWT signing"
echo "=========================================="
