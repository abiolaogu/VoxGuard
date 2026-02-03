// Package service provides security business logic
package service

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	vault "github.com/hashicorp/vault/api"
	"go.uber.org/zap"
)

// HashiCorpVaultClient implements VaultClient interface
type HashiCorpVaultClient struct {
	client     *vault.Client
	mountPath  string
	logger     *zap.Logger
	tokenRenew chan struct{}
}

// VaultConfig holds configuration for Vault client
type VaultConfig struct {
	Address   string
	Token     string
	MountPath string // KV secrets engine mount path (default: "secret")
	Namespace string // Enterprise feature
}

// NewVaultClient creates a new HashiCorp Vault client
func NewVaultClient(config VaultConfig, logger *zap.Logger) (*HashiCorpVaultClient, error) {
	if config.Address == "" {
		return nil, fmt.Errorf("vault address is required")
	}

	vaultConfig := vault.DefaultConfig()
	vaultConfig.Address = config.Address

	client, err := vault.NewClient(vaultConfig)
	if err != nil {
		return nil, fmt.Errorf("create vault client: %w", err)
	}

	if config.Token != "" {
		client.SetToken(config.Token)
	}

	if config.Namespace != "" {
		client.SetNamespace(config.Namespace)
	}

	if config.MountPath == "" {
		config.MountPath = "secret"
	}

	vaultClient := &HashiCorpVaultClient{
		client:     client,
		mountPath:  config.MountPath,
		logger:     logger,
		tokenRenew: make(chan struct{}),
	}

	// Verify connection
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if _, err := client.Sys().Health(); err != nil {
		logger.Warn("Vault health check failed", zap.Error(err))
		// Don't fail initialization, as Vault might be temporarily unavailable
	}

	// Start token renewal goroutine if token is provided
	if config.Token != "" {
		go vaultClient.renewToken()
	}

	logger.Info("Vault client initialized",
		zap.String("address", config.Address),
		zap.String("mount_path", config.MountPath))

	return vaultClient, nil
}

// GetSecret retrieves a secret from Vault
func (v *HashiCorpVaultClient) GetSecret(ctx context.Context, path string) (map[string]interface{}, error) {
	fullPath := fmt.Sprintf("%s/data/%s", v.mountPath, path)

	secret, err := v.client.Logical().ReadWithContext(ctx, fullPath)
	if err != nil {
		return nil, fmt.Errorf("read secret from vault: %w", err)
	}

	if secret == nil {
		return nil, fmt.Errorf("secret not found: %s", path)
	}

	// KV v2 stores data in a "data" field
	if data, ok := secret.Data["data"].(map[string]interface{}); ok {
		return data, nil
	}

	// KV v1 or direct data
	return secret.Data, nil
}

// PutSecret stores a secret in Vault
func (v *HashiCorpVaultClient) PutSecret(ctx context.Context, path string, data map[string]interface{}) error {
	fullPath := fmt.Sprintf("%s/data/%s", v.mountPath, path)

	// KV v2 requires data to be wrapped in a "data" field
	wrappedData := map[string]interface{}{
		"data": data,
	}

	_, err := v.client.Logical().WriteWithContext(ctx, fullPath, wrappedData)
	if err != nil {
		return fmt.Errorf("write secret to vault: %w", err)
	}

	v.logger.Debug("Secret written to Vault", zap.String("path", path))
	return nil
}

// DeleteSecret deletes a secret from Vault
func (v *HashiCorpVaultClient) DeleteSecret(ctx context.Context, path string) error {
	fullPath := fmt.Sprintf("%s/data/%s", v.mountPath, path)

	_, err := v.client.Logical().DeleteWithContext(ctx, fullPath)
	if err != nil {
		return fmt.Errorf("delete secret from vault: %w", err)
	}

	v.logger.Debug("Secret deleted from Vault", zap.String("path", path))
	return nil
}

// GetDatabaseCredentials retrieves database credentials from Vault
func (v *HashiCorpVaultClient) GetDatabaseCredentials(ctx context.Context, role string) (*DatabaseCredentials, error) {
	path := fmt.Sprintf("database/creds/%s", role)

	secret, err := v.client.Logical().ReadWithContext(ctx, path)
	if err != nil {
		return nil, fmt.Errorf("read database credentials: %w", err)
	}

	if secret == nil {
		return nil, fmt.Errorf("database credentials not found for role: %s", role)
	}

	creds := &DatabaseCredentials{
		Username:  secret.Data["username"].(string),
		Password:  secret.Data["password"].(string),
		LeaseID:   secret.LeaseID,
		Renewable: secret.Renewable,
	}

	if secret.LeaseDuration > 0 {
		expiresAt := time.Now().Add(time.Duration(secret.LeaseDuration) * time.Second)
		creds.ExpiresAt = &expiresAt
	}

	v.logger.Debug("Retrieved database credentials from Vault",
		zap.String("role", role),
		zap.String("username", creds.Username))

	return creds, nil
}

// RenewDatabaseLease renews a database credential lease
func (v *HashiCorpVaultClient) RenewDatabaseLease(ctx context.Context, leaseID string) error {
	secret, err := v.client.Sys().RenewWithContext(ctx, leaseID, 0)
	if err != nil {
		return fmt.Errorf("renew lease: %w", err)
	}

	v.logger.Debug("Renewed database lease",
		zap.String("lease_id", leaseID),
		zap.Int("lease_duration", secret.LeaseDuration))

	return nil
}

// RevokeDatabaseLease revokes a database credential lease
func (v *HashiCorpVaultClient) RevokeDatabaseLease(ctx context.Context, leaseID string) error {
	err := v.client.Sys().RevokeWithContext(ctx, leaseID)
	if err != nil {
		return fmt.Errorf("revoke lease: %w", err)
	}

	v.logger.Debug("Revoked database lease", zap.String("lease_id", leaseID))
	return nil
}

// GenerateRSAKeyPair generates an RSA key pair using Vault's Transit engine
func (v *HashiCorpVaultClient) GenerateRSAKeyPair(ctx context.Context, keyName string) error {
	path := fmt.Sprintf("transit/keys/%s", keyName)

	data := map[string]interface{}{
		"type": "rsa-2048",
	}

	_, err := v.client.Logical().WriteWithContext(ctx, path, data)
	if err != nil {
		return fmt.Errorf("generate RSA key pair: %w", err)
	}

	v.logger.Info("Generated RSA key pair in Vault", zap.String("key_name", keyName))
	return nil
}

// SignData signs data using Vault's Transit engine
func (v *HashiCorpVaultClient) SignData(ctx context.Context, keyName string, data []byte) (string, error) {
	path := fmt.Sprintf("transit/sign/%s", keyName)

	payload := map[string]interface{}{
		"input": data,
	}

	secret, err := v.client.Logical().WriteWithContext(ctx, path, payload)
	if err != nil {
		return "", fmt.Errorf("sign data: %w", err)
	}

	signature, ok := secret.Data["signature"].(string)
	if !ok {
		return "", fmt.Errorf("invalid signature response")
	}

	return signature, nil
}

// EncryptData encrypts data using Vault's Transit engine
func (v *HashiCorpVaultClient) EncryptData(ctx context.Context, keyName string, plaintext []byte) (string, error) {
	path := fmt.Sprintf("transit/encrypt/%s", keyName)

	payload := map[string]interface{}{
		"plaintext": plaintext,
	}

	secret, err := v.client.Logical().WriteWithContext(ctx, path, payload)
	if err != nil {
		return "", fmt.Errorf("encrypt data: %w", err)
	}

	ciphertext, ok := secret.Data["ciphertext"].(string)
	if !ok {
		return "", fmt.Errorf("invalid ciphertext response")
	}

	return ciphertext, nil
}

// DecryptData decrypts data using Vault's Transit engine
func (v *HashiCorpVaultClient) DecryptData(ctx context.Context, keyName string, ciphertext string) ([]byte, error) {
	path := fmt.Sprintf("transit/decrypt/%s", keyName)

	payload := map[string]interface{}{
		"ciphertext": ciphertext,
	}

	secret, err := v.client.Logical().WriteWithContext(ctx, path, payload)
	if err != nil {
		return nil, fmt.Errorf("decrypt data: %w", err)
	}

	plaintext, ok := secret.Data["plaintext"].([]byte)
	if !ok {
		return nil, fmt.Errorf("invalid plaintext response")
	}

	return plaintext, nil
}

// GetJWTSigningKey retrieves the JWT signing key from Vault
func (v *HashiCorpVaultClient) GetJWTSigningKey(ctx context.Context) (*JWTKeyPair, error) {
	data, err := v.GetSecret(ctx, "jwt/signing-key")
	if err != nil {
		return nil, err
	}

	keyPair := &JWTKeyPair{
		PrivateKey: data["private_key"].(string),
		PublicKey:  data["public_key"].(string),
	}

	if createdAt, ok := data["created_at"].(string); ok {
		if t, err := time.Parse(time.RFC3339, createdAt); err == nil {
			keyPair.CreatedAt = t
		}
	}

	return keyPair, nil
}

// StoreJWTSigningKey stores the JWT signing key in Vault
func (v *HashiCorpVaultClient) StoreJWTSigningKey(ctx context.Context, privateKey, publicKey string) error {
	data := map[string]interface{}{
		"private_key": privateKey,
		"public_key":  publicKey,
		"created_at":  time.Now().Format(time.RFC3339),
	}

	return v.PutSecret(ctx, "jwt/signing-key", data)
}

// GetNCCCredentials retrieves NCC API credentials from Vault
func (v *HashiCorpVaultClient) GetNCCCredentials(ctx context.Context) (*NCCCredentials, error) {
	data, err := v.GetSecret(ctx, "ncc/credentials")
	if err != nil {
		return nil, err
	}

	creds := &NCCCredentials{
		ClientID:     data["client_id"].(string),
		ClientSecret: data["client_secret"].(string),
		APIBaseURL:   data["api_base_url"].(string),
	}

	if sftpHost, ok := data["sftp_host"].(string); ok {
		creds.SFTPHost = sftpHost
	}
	if sftpUser, ok := data["sftp_user"].(string); ok {
		creds.SFTPUser = sftpUser
	}
	if sftpKey, ok := data["sftp_private_key"].(string); ok {
		creds.SFTPPrivateKey = sftpKey
	}

	return creds, nil
}

// StoreNCCCredentials stores NCC API credentials in Vault
func (v *HashiCorpVaultClient) StoreNCCCredentials(ctx context.Context, creds *NCCCredentials) error {
	data := map[string]interface{}{
		"client_id":        creds.ClientID,
		"client_secret":    creds.ClientSecret,
		"api_base_url":     creds.APIBaseURL,
		"sftp_host":        creds.SFTPHost,
		"sftp_user":        creds.SFTPUser,
		"sftp_private_key": creds.SFTPPrivateKey,
	}

	return v.PutSecret(ctx, "ncc/credentials", data)
}

// renewToken automatically renews the Vault token before it expires
func (v *HashiCorpVaultClient) renewToken() {
	ticker := time.NewTicker(1 * time.Hour)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			secret, err := v.client.Auth().Token().RenewSelfWithContext(ctx, 0)
			cancel()

			if err != nil {
				v.logger.Error("Failed to renew Vault token", zap.Error(err))
			} else {
				v.logger.Debug("Renewed Vault token",
					zap.Int("lease_duration", secret.Auth.LeaseDuration))
			}

		case <-v.tokenRenew:
			v.logger.Info("Stopping Vault token renewal")
			return
		}
	}
}

// Close stops the token renewal goroutine
func (v *HashiCorpVaultClient) Close() error {
	close(v.tokenRenew)
	return nil
}

// Health checks Vault health status
func (v *HashiCorpVaultClient) Health(ctx context.Context) error {
	health, err := v.client.Sys().Health()
	if err != nil {
		return fmt.Errorf("vault health check failed: %w", err)
	}

	if !health.Initialized {
		return fmt.Errorf("vault is not initialized")
	}

	if health.Sealed {
		return fmt.Errorf("vault is sealed")
	}

	return nil
}

// ListSecrets lists all secrets at a given path
func (v *HashiCorpVaultClient) ListSecrets(ctx context.Context, path string) ([]string, error) {
	fullPath := fmt.Sprintf("%s/metadata/%s", v.mountPath, path)

	secret, err := v.client.Logical().ListWithContext(ctx, fullPath)
	if err != nil {
		return nil, fmt.Errorf("list secrets: %w", err)
	}

	if secret == nil || secret.Data == nil {
		return []string{}, nil
	}

	keys, ok := secret.Data["keys"].([]interface{})
	if !ok {
		return []string{}, nil
	}

	result := make([]string, 0, len(keys))
	for _, key := range keys {
		if keyStr, ok := key.(string); ok {
			result = append(result, keyStr)
		}
	}

	return result, nil
}

// GetSecretMetadata retrieves metadata for a secret
func (v *HashiCorpVaultClient) GetSecretMetadata(ctx context.Context, path string) (*SecretMetadata, error) {
	fullPath := fmt.Sprintf("%s/metadata/%s", v.mountPath, path)

	secret, err := v.client.Logical().ReadWithContext(ctx, fullPath)
	if err != nil {
		return nil, fmt.Errorf("read secret metadata: %w", err)
	}

	if secret == nil {
		return nil, fmt.Errorf("secret metadata not found: %s", path)
	}

	metadata := &SecretMetadata{}

	if createdTime, ok := secret.Data["created_time"].(string); ok {
		if t, err := time.Parse(time.RFC3339, createdTime); err == nil {
			metadata.CreatedTime = t
		}
	}

	if updatedTime, ok := secret.Data["updated_time"].(string); ok {
		if t, err := time.Parse(time.RFC3339, updatedTime); err == nil {
			metadata.UpdatedTime = t
		}
	}

	if currentVersion, ok := secret.Data["current_version"].(json.Number); ok {
		if v, err := currentVersion.Int64(); err == nil {
			metadata.CurrentVersion = int(v)
		}
	}

	return metadata, nil
}

// Supporting types

// DatabaseCredentials represents dynamic database credentials from Vault
type DatabaseCredentials struct {
	Username  string
	Password  string
	LeaseID   string
	ExpiresAt *time.Time
	Renewable bool
}

// JWTKeyPair represents an RSA key pair for JWT signing
type JWTKeyPair struct {
	PrivateKey string
	PublicKey  string
	CreatedAt  time.Time
}

// NCCCredentials represents NCC API credentials
type NCCCredentials struct {
	ClientID       string
	ClientSecret   string
	APIBaseURL     string
	SFTPHost       string
	SFTPUser       string
	SFTPPrivateKey string
}

// SecretMetadata represents metadata about a secret
type SecretMetadata struct {
	CreatedTime    time.Time
	UpdatedTime    time.Time
	CurrentVersion int
}
