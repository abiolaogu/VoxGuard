# VoxGuard Application Policy
# This policy grants the Management API access to required secrets

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

# Allow reading encryption keys
path "transit/encrypt/voxguard-*" {
  capabilities = ["update"]
}

path "transit/decrypt/voxguard-*" {
  capabilities = ["update"]
}

# Allow reading public keys for JWT verification
path "transit/keys/voxguard-jwt" {
  capabilities = ["read"]
}

# Allow signing with JWT key
path "transit/sign/voxguard-jwt" {
  capabilities = ["update"]
}

# Allow verifying signatures
path "transit/verify/voxguard-jwt" {
  capabilities = ["update"]
}

# Token self-renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Token lookup
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
