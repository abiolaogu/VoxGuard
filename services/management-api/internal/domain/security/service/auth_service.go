// Package service provides security business logic
package service

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"errors"
	"fmt"
	"time"

	"github.com/billyronks/acm-management-api/internal/domain/security/entity"
	"github.com/billyronks/acm-management-api/internal/domain/security/repository"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"go.uber.org/zap"
	"golang.org/x/crypto/bcrypt"
)

// AuthService handles authentication and token management
type AuthService struct {
	repo          repository.SecurityRepository
	auditService  AuditLogger
	vaultClient   VaultClient
	logger        *zap.Logger
	privateKey    *rsa.PrivateKey
	publicKey     *rsa.PublicKey
	issuer        string
	accessExpiry  time.Duration
	refreshExpiry time.Duration
}

// VaultClient interface for HashiCorp Vault operations
type VaultClient interface {
	GetSecret(ctx context.Context, path string) (map[string]interface{}, error)
	PutSecret(ctx context.Context, path string, data map[string]interface{}) error
}

// AuthServiceConfig holds configuration for AuthService
type AuthServiceConfig struct {
	Issuer              string
	AccessTokenExpiry   time.Duration
	RefreshTokenExpiry  time.Duration
	PrivateKeyPEM       string // RSA private key in PEM format
	PublicKeyPEM        string // RSA public key in PEM format
	GenerateKeysIfEmpty bool   // Generate keys if not provided
}

// NewAuthService creates a new authentication service
func NewAuthService(
	repo repository.SecurityRepository,
	auditService AuditLogger,
	vaultClient VaultClient,
	logger *zap.Logger,
	config AuthServiceConfig,
) (*AuthService, error) {
	var privateKey *rsa.PrivateKey
	var publicKey *rsa.PublicKey
	var err error

	// Load or generate RSA keys
	if config.PrivateKeyPEM != "" && config.PublicKeyPEM != "" {
		privateKey, err = parsePrivateKey(config.PrivateKeyPEM)
		if err != nil {
			return nil, fmt.Errorf("parse private key: %w", err)
		}
		publicKey, err = parsePublicKey(config.PublicKeyPEM)
		if err != nil {
			return nil, fmt.Errorf("parse public key: %w", err)
		}
	} else if config.GenerateKeysIfEmpty {
		logger.Info("Generating new RSA key pair for JWT signing")
		privateKey, err = rsa.GenerateKey(rand.Reader, 2048)
		if err != nil {
			return nil, fmt.Errorf("generate RSA key: %w", err)
		}
		publicKey = &privateKey.PublicKey
	} else {
		return nil, errors.New("RSA keys not provided and generation not enabled")
	}

	if config.Issuer == "" {
		config.Issuer = "voxguard-management-api"
	}
	if config.AccessTokenExpiry == 0 {
		config.AccessTokenExpiry = 15 * time.Minute
	}
	if config.RefreshTokenExpiry == 0 {
		config.RefreshTokenExpiry = 7 * 24 * time.Hour
	}

	return &AuthService{
		repo:          repo,
		auditService:  auditService,
		vaultClient:   vaultClient,
		logger:        logger,
		privateKey:    privateKey,
		publicKey:     publicKey,
		issuer:        config.Issuer,
		accessExpiry:  config.AccessTokenExpiry,
		refreshExpiry: config.RefreshTokenExpiry,
	}, nil
}

// Login authenticates a user and returns tokens
func (s *AuthService) Login(ctx context.Context, req entity.LoginRequest, ipAddress, userAgent string) (*entity.LoginResponse, error) {
	// Get user by username
	user, err := s.repo.GetUserByUsername(ctx, req.Username)
	if err != nil {
		// Don't reveal if user exists or not
		s.logger.Warn("Login attempt for non-existent user", zap.String("username", req.Username))
		return nil, errors.New("invalid credentials")
	}

	// Check if account is locked
	if user.IsLocked {
		if user.LockedUntil != nil && time.Now().Before(*user.LockedUntil) {
			s.auditService.LogAuthEvent(ctx, user.ID, user.Username, "login_locked", ipAddress, userAgent, false, "Account is locked")
			return nil, errors.New("account is locked")
		}
		// Unlock if lock period has expired
		if err := s.repo.UnlockUser(ctx, user.ID); err != nil {
			s.logger.Error("Failed to unlock user", zap.Error(err))
		}
		user.IsLocked = false
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		// Increment login attempts
		attempts, lockErr := s.repo.IncrementLoginAttempts(ctx, user.ID)
		if lockErr != nil {
			s.logger.Error("Failed to increment login attempts", zap.Error(lockErr))
		}

		// Lock account if threshold exceeded
		if attempts >= 5 {
			lockUntil := time.Now().Add(30 * time.Minute)
			if lockErr := s.repo.LockUser(ctx, user.ID, lockUntil); lockErr != nil {
				s.logger.Error("Failed to lock user", zap.Error(lockErr))
			}
			s.auditService.LogAuthEvent(ctx, user.ID, user.Username, "account_locked", ipAddress, userAgent, true, "Too many failed login attempts")
		}

		s.auditService.LogAuthEvent(ctx, user.ID, user.Username, "login_failure", ipAddress, userAgent, false, "Invalid password")
		return nil, errors.New("invalid credentials")
	}

	// Check if account is active
	if !user.IsActive {
		s.auditService.LogAuthEvent(ctx, user.ID, user.Username, "login_inactive", ipAddress, userAgent, false, "Account is inactive")
		return nil, errors.New("account is inactive")
	}

	// Verify MFA if enabled
	if user.MFAEnabled {
		if req.MFACode == "" {
			return nil, errors.New("mfa code required")
		}
		if !s.verifyMFACode(user.MFASecret, req.MFACode) {
			s.auditService.LogAuthEvent(ctx, user.ID, user.Username, "login_mfa_failure", ipAddress, userAgent, false, "Invalid MFA code")
			return nil, errors.New("invalid mfa code")
		}
	}

	// Get user roles and permissions
	roles, err := s.repo.GetUserRoles(ctx, user.ID)
	if err != nil {
		s.logger.Error("Failed to get user roles", zap.Error(err))
		return nil, errors.New("failed to get user roles")
	}

	permissions, err := s.repo.GetUserPermissions(ctx, user.ID)
	if err != nil {
		s.logger.Error("Failed to get user permissions", zap.Error(err))
		return nil, errors.New("failed to get user permissions")
	}

	// Generate access token
	accessToken, accessExp, err := s.generateAccessToken(user, roles, permissions)
	if err != nil {
		s.logger.Error("Failed to generate access token", zap.Error(err))
		return nil, errors.New("failed to generate token")
	}

	// Generate refresh token
	refreshToken, _, err := s.generateRefreshToken(ctx, user.ID, ipAddress, userAgent)
	if err != nil {
		s.logger.Error("Failed to generate refresh token", zap.Error(err))
		return nil, errors.New("failed to generate token")
	}

	// Reset login attempts and update last login
	if err := s.repo.ResetLoginAttempts(ctx, user.ID); err != nil {
		s.logger.Error("Failed to reset login attempts", zap.Error(err))
	}
	if err := s.repo.UpdateLastLogin(ctx, user.ID); err != nil {
		s.logger.Error("Failed to update last login", zap.Error(err))
	}

	// Log successful login
	s.auditService.LogAuthEvent(ctx, user.ID, user.Username, "login_success", ipAddress, userAgent, true, "")

	return &entity.LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		TokenType:    "Bearer",
		ExpiresAt:    accessExp,
		User: entity.UserInfo{
			ID:          user.ID,
			Username:    user.Username,
			Email:       user.Email,
			FirstName:   user.FirstName,
			LastName:    user.LastName,
			Roles:       roles,
			Permissions: permissions,
		},
	}, nil
}

// RefreshToken generates a new access token using a refresh token
func (s *AuthService) RefreshToken(ctx context.Context, refreshTokenStr string) (*entity.LoginResponse, error) {
	// Hash the refresh token to look it up
	tokenHash := hashToken(refreshTokenStr)

	// Get refresh token from database
	refreshToken, err := s.repo.GetRefreshToken(ctx, tokenHash)
	if err != nil {
		return nil, errors.New("invalid refresh token")
	}

	// Check if token is revoked
	if refreshToken.IsRevoked {
		return nil, errors.New("refresh token has been revoked")
	}

	// Check if token is expired
	if time.Now().After(refreshToken.ExpiresAt) {
		return nil, errors.New("refresh token has expired")
	}

	// Get user
	user, err := s.repo.GetUserByID(ctx, refreshToken.UserID)
	if err != nil {
		return nil, errors.New("user not found")
	}

	// Check if user is active
	if !user.IsActive {
		return nil, errors.New("user is inactive")
	}

	// Get user roles and permissions
	roles, err := s.repo.GetUserRoles(ctx, user.ID)
	if err != nil {
		return nil, errors.New("failed to get user roles")
	}

	permissions, err := s.repo.GetUserPermissions(ctx, user.ID)
	if err != nil {
		return nil, errors.New("failed to get user permissions")
	}

	// Generate new access token
	accessToken, accessExp, err := s.generateAccessToken(user, roles, permissions)
	if err != nil {
		return nil, errors.New("failed to generate token")
	}

	// Update last used timestamp
	if err := s.repo.UpdateRefreshTokenLastUsed(ctx, refreshToken.ID); err != nil {
		s.logger.Error("Failed to update refresh token last used", zap.Error(err))
	}

	return &entity.LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshTokenStr,
		TokenType:    "Bearer",
		ExpiresAt:    accessExp,
		User: entity.UserInfo{
			ID:          user.ID,
			Username:    user.Username,
			Email:       user.Email,
			FirstName:   user.FirstName,
			LastName:    user.LastName,
			Roles:       roles,
			Permissions: permissions,
		},
	}, nil
}

// ValidateToken validates a JWT access token and returns claims
func (s *AuthService) ValidateToken(tokenString string) (*entity.JWTClaims, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		// Verify signing method
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return s.publicKey, nil
	})

	if err != nil {
		return nil, fmt.Errorf("parse token: %w", err)
	}

	if !token.Valid {
		return nil, errors.New("invalid token")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("invalid claims format")
	}

	// Extract claims
	jwtClaims := &entity.JWTClaims{
		UserID:    getStringClaim(claims, "user_id"),
		Username:  getStringClaim(claims, "username"),
		Email:     getStringClaim(claims, "email"),
		TokenType: getStringClaim(claims, "token_type"),
		Issuer:    getStringClaim(claims, "iss"),
		Subject:   getStringClaim(claims, "sub"),
		JTI:       getStringClaim(claims, "jti"),
	}

	if roles, ok := claims["roles"].([]interface{}); ok {
		for _, r := range roles {
			if role, ok := r.(string); ok {
				jwtClaims.Roles = append(jwtClaims.Roles, role)
			}
		}
	}

	if perms, ok := claims["permissions"].([]interface{}); ok {
		for _, p := range perms {
			if perm, ok := p.(string); ok {
				jwtClaims.Permissions = append(jwtClaims.Permissions, perm)
			}
		}
	}

	if iat, ok := claims["iat"].(float64); ok {
		jwtClaims.IssuedAt = int64(iat)
	}
	if exp, ok := claims["exp"].(float64); ok {
		jwtClaims.ExpiresAt = int64(exp)
	}
	if nbf, ok := claims["nbf"].(float64); ok {
		jwtClaims.NotBefore = int64(nbf)
	}

	return jwtClaims, nil
}

// Logout revokes a refresh token
func (s *AuthService) Logout(ctx context.Context, refreshTokenStr string) error {
	tokenHash := hashToken(refreshTokenStr)
	return s.repo.RevokeRefreshToken(ctx, tokenHash)
}

// RevokeAllTokens revokes all refresh tokens for a user
func (s *AuthService) RevokeAllTokens(ctx context.Context, userID string) error {
	return s.repo.RevokeAllUserTokens(ctx, userID)
}

// ChangePassword changes a user's password
func (s *AuthService) ChangePassword(ctx context.Context, userID string, oldPassword, newPassword string) error {
	user, err := s.repo.GetUserByID(ctx, userID)
	if err != nil {
		return errors.New("user not found")
	}

	// Verify old password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(oldPassword)); err != nil {
		return errors.New("invalid old password")
	}

	// Validate new password
	if err := s.validatePassword(newPassword); err != nil {
		return err
	}

	// Check password history
	if err := s.repo.CheckPasswordHistory(ctx, userID, newPassword); err != nil {
		return errors.New("password has been used recently")
	}

	// Hash new password
	passwordHash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("hash password: %w", err)
	}

	// Update password
	if err := s.repo.UpdatePassword(ctx, userID, string(passwordHash)); err != nil {
		return fmt.Errorf("update password: %w", err)
	}

	// Add to password history
	if err := s.repo.AddPasswordHistory(ctx, userID, string(passwordHash)); err != nil {
		s.logger.Error("Failed to add password to history", zap.Error(err))
	}

	// Revoke all existing tokens
	if err := s.RevokeAllTokens(ctx, userID); err != nil {
		s.logger.Error("Failed to revoke tokens after password change", zap.Error(err))
	}

	return nil
}

// Helper functions

func (s *AuthService) generateAccessToken(user *entity.User, roles, permissions []string) (string, time.Time, error) {
	now := time.Now()
	expiresAt := now.Add(s.accessExpiry)

	claims := jwt.MapClaims{
		"user_id":     user.ID,
		"username":    user.Username,
		"email":       user.Email,
		"roles":       roles,
		"permissions": permissions,
		"token_type":  "access",
		"iat":         now.Unix(),
		"exp":         expiresAt.Unix(),
		"nbf":         now.Unix(),
		"iss":         s.issuer,
		"sub":         user.ID,
		"jti":         uuid.New().String(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	tokenString, err := token.SignedString(s.privateKey)
	if err != nil {
		return "", time.Time{}, fmt.Errorf("sign token: %w", err)
	}

	return tokenString, expiresAt, nil
}

func (s *AuthService) generateRefreshToken(ctx context.Context, userID, ipAddress, userAgent string) (string, time.Time, error) {
	// Generate random token
	tokenBytes := make([]byte, 32)
	if _, err := rand.Read(tokenBytes); err != nil {
		return "", time.Time{}, fmt.Errorf("generate random token: %w", err)
	}
	tokenString := base64.URLEncoding.EncodeToString(tokenBytes)

	// Hash token for storage
	tokenHash := hashToken(tokenString)

	expiresAt := time.Now().Add(s.refreshExpiry)

	// Store refresh token
	refreshToken := &entity.RefreshToken{
		ID:        uuid.New().String(),
		UserID:    userID,
		TokenHash: tokenHash,
		ExpiresAt: expiresAt,
		IsRevoked: false,
		IPAddress: ipAddress,
		UserAgent: userAgent,
	}

	if err := s.repo.CreateRefreshToken(ctx, refreshToken); err != nil {
		return "", time.Time{}, fmt.Errorf("store refresh token: %w", err)
	}

	return tokenString, expiresAt, nil
}

func (s *AuthService) validatePassword(password string) error {
	// Implement password policy validation
	if len(password) < 12 {
		return errors.New("password must be at least 12 characters")
	}

	hasUpper := false
	hasLower := false
	hasNumber := false
	hasSpecial := false

	for _, char := range password {
		switch {
		case 'A' <= char && char <= 'Z':
			hasUpper = true
		case 'a' <= char && char <= 'z':
			hasLower = true
		case '0' <= char && char <= '9':
			hasNumber = true
		case char == '!' || char == '@' || char == '#' || char == '$' || char == '%' || char == '^' || char == '&' || char == '*':
			hasSpecial = true
		}
	}

	if !hasUpper {
		return errors.New("password must contain at least one uppercase letter")
	}
	if !hasLower {
		return errors.New("password must contain at least one lowercase letter")
	}
	if !hasNumber {
		return errors.New("password must contain at least one number")
	}
	if !hasSpecial {
		return errors.New("password must contain at least one special character")
	}

	return nil
}

func (s *AuthService) verifyMFACode(secret, code string) bool {
	// TODO: Implement TOTP verification
	// For now, return true for development
	return true
}

func hashToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return base64.URLEncoding.EncodeToString(hash[:])
}

func parsePrivateKey(pemStr string) (*rsa.PrivateKey, error) {
	block, _ := pem.Decode([]byte(pemStr))
	if block == nil {
		return nil, errors.New("failed to parse PEM block")
	}

	privateKey, err := x509.ParsePKCS1PrivateKey(block.Bytes)
	if err != nil {
		// Try PKCS8 format
		key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
		if err != nil {
			return nil, fmt.Errorf("parse private key: %w", err)
		}
		var ok bool
		privateKey, ok = key.(*rsa.PrivateKey)
		if !ok {
			return nil, errors.New("not an RSA private key")
		}
	}

	return privateKey, nil
}

func parsePublicKey(pemStr string) (*rsa.PublicKey, error) {
	block, _ := pem.Decode([]byte(pemStr))
	if block == nil {
		return nil, errors.New("failed to parse PEM block")
	}

	pub, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("parse public key: %w", err)
	}

	publicKey, ok := pub.(*rsa.PublicKey)
	if !ok {
		return nil, errors.New("not an RSA public key")
	}

	return publicKey, nil
}

func getStringClaim(claims jwt.MapClaims, key string) string {
	if val, ok := claims[key].(string); ok {
		return val
	}
	return ""
}

// ExportPublicKey exports the public key in PEM format
func (s *AuthService) ExportPublicKey() (string, error) {
	pubKeyBytes, err := x509.MarshalPKIXPublicKey(s.publicKey)
	if err != nil {
		return "", fmt.Errorf("marshal public key: %w", err)
	}

	pubKeyPEM := pem.EncodeToMemory(&pem.Block{
		Type:  "RSA PUBLIC KEY",
		Bytes: pubKeyBytes,
	})

	return string(pubKeyPEM), nil
}
