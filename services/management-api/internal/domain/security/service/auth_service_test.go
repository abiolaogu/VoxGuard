package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/billyronks/acm-management-api/internal/domain/security/entity"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.uber.org/zap"
	"golang.org/x/crypto/bcrypt"
)

// MockVaultClient is a mock implementation of VaultClient
type MockVaultClient struct {
	mock.Mock
}

func (m *MockVaultClient) GetSecret(ctx context.Context, path string) (map[string]interface{}, error) {
	args := m.Called(ctx, path)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(map[string]interface{}), args.Error(1)
}

func (m *MockVaultClient) PutSecret(ctx context.Context, path string, data map[string]interface{}) error {
	args := m.Called(ctx, path, data)
	return args.Error(0)
}

// Test NewAuthService - Success with key generation
func TestNewAuthService_GenerateKeys(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		Issuer:              "test-issuer",
		AccessTokenExpiry:   15 * time.Minute,
		RefreshTokenExpiry:  7 * 24 * time.Hour,
		GenerateKeysIfEmpty: true,
	}

	service, err := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	assert.NoError(t, err)
	assert.NotNil(t, service)
	assert.NotNil(t, service.privateKey)
	assert.NotNil(t, service.publicKey)
	assert.Equal(t, "test-issuer", service.issuer)
}

// Test NewAuthService - Failure without keys
func TestNewAuthService_NoKeys(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		Issuer:              "test-issuer",
		GenerateKeysIfEmpty: false,
	}

	service, err := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	assert.Error(t, err)
	assert.Nil(t, service)
	assert.Contains(t, err.Error(), "RSA keys not provided")
}

// Test Login - Success
func TestLogin_Success(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	ctx := context.Background()
	password := "TestPassword123!"
	passwordHash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)

	user := &entity.User{
		ID:           "user-123",
		Username:     "john.doe",
		Email:        "john@example.com",
		FirstName:    "John",
		LastName:     "Doe",
		PasswordHash: string(passwordHash),
		IsActive:     true,
		IsLocked:     false,
		MFAEnabled:   false,
	}

	loginReq := entity.LoginRequest{
		Username: "john.doe",
		Password: password,
	}

	mockRepo.On("GetUserByUsername", ctx, "john.doe").Return(user, nil)
	mockRepo.On("GetUserRoles", ctx, user.ID).Return([]string{"analyst"}, nil)
	mockRepo.On("GetUserPermissions", ctx, user.ID).Return([]string{"gateway:read"}, nil)
	mockRepo.On("CreateRefreshToken", ctx, mock.AnythingOfType("*entity.RefreshToken")).Return(nil)
	mockRepo.On("ResetLoginAttempts", ctx, user.ID).Return(nil)
	mockRepo.On("UpdateLastLogin", ctx, user.ID).Return(nil)
	mockAudit.On("LogAuthEvent", ctx, user.ID, user.Username, "login_success", "", "", true, "").Return()

	response, err := service.Login(ctx, loginReq, "", "")

	assert.NoError(t, err)
	assert.NotNil(t, response)
	assert.NotEmpty(t, response.AccessToken)
	assert.NotEmpty(t, response.RefreshToken)
	assert.Equal(t, "Bearer", response.TokenType)
	assert.Equal(t, user.ID, response.User.ID)
	assert.Equal(t, user.Username, response.User.Username)
	mockRepo.AssertExpectations(t)
	mockAudit.AssertExpectations(t)
}

// Test Login - Invalid credentials
func TestLogin_InvalidCredentials(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	ctx := context.Background()

	loginReq := entity.LoginRequest{
		Username: "nonexistent",
		Password: "wrongpassword",
	}

	mockRepo.On("GetUserByUsername", ctx, "nonexistent").Return(nil, errors.New("not found"))

	response, err := service.Login(ctx, loginReq, "", "")

	assert.Error(t, err)
	assert.Nil(t, response)
	assert.Contains(t, err.Error(), "invalid credentials")
	mockRepo.AssertExpectations(t)
}

// Test Login - Account locked
func TestLogin_AccountLocked(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	ctx := context.Background()
	lockUntil := time.Now().Add(30 * time.Minute)

	user := &entity.User{
		ID:          "user-123",
		Username:    "john.doe",
		IsActive:    true,
		IsLocked:    true,
		LockedUntil: &lockUntil,
	}

	loginReq := entity.LoginRequest{
		Username: "john.doe",
		Password: "password",
	}

	mockRepo.On("GetUserByUsername", ctx, "john.doe").Return(user, nil)
	mockAudit.On("LogAuthEvent", ctx, user.ID, user.Username, "login_locked", "", "", false, "Account is locked").Return()

	response, err := service.Login(ctx, loginReq, "", "")

	assert.Error(t, err)
	assert.Nil(t, response)
	assert.Contains(t, err.Error(), "account is locked")
	mockRepo.AssertExpectations(t)
	mockAudit.AssertExpectations(t)
}

// Test Login - Inactive account
func TestLogin_InactiveAccount(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	ctx := context.Background()
	password := "TestPassword123!"
	passwordHash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)

	user := &entity.User{
		ID:           "user-123",
		Username:     "john.doe",
		PasswordHash: string(passwordHash),
		IsActive:     false,
		IsLocked:     false,
	}

	loginReq := entity.LoginRequest{
		Username: "john.doe",
		Password: password,
	}

	mockRepo.On("GetUserByUsername", ctx, "john.doe").Return(user, nil)
	mockAudit.On("LogAuthEvent", ctx, user.ID, user.Username, "login_inactive", "", "", false, "Account is inactive").Return()

	response, err := service.Login(ctx, loginReq, "", "")

	assert.Error(t, err)
	assert.Nil(t, response)
	assert.Contains(t, err.Error(), "account is inactive")
	mockRepo.AssertExpectations(t)
	mockAudit.AssertExpectations(t)
}

// Test Login - Wrong password with lockout
func TestLogin_WrongPassword_Lockout(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	ctx := context.Background()
	password := "CorrectPassword123!"
	passwordHash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)

	user := &entity.User{
		ID:           "user-123",
		Username:     "john.doe",
		PasswordHash: string(passwordHash),
		IsActive:     true,
		IsLocked:     false,
	}

	loginReq := entity.LoginRequest{
		Username: "john.doe",
		Password: "WrongPassword",
	}

	mockRepo.On("GetUserByUsername", ctx, "john.doe").Return(user, nil)
	mockRepo.On("IncrementLoginAttempts", ctx, user.ID).Return(5, nil)
	mockRepo.On("LockUser", ctx, user.ID, mock.AnythingOfType("time.Time")).Return(nil)
	mockAudit.On("LogAuthEvent", ctx, user.ID, user.Username, "account_locked", "", "", true, "Too many failed login attempts").Return()
	mockAudit.On("LogAuthEvent", ctx, user.ID, user.Username, "login_failure", "", "", false, "Invalid password").Return()

	response, err := service.Login(ctx, loginReq, "", "")

	assert.Error(t, err)
	assert.Nil(t, response)
	assert.Contains(t, err.Error(), "invalid credentials")
	mockRepo.AssertExpectations(t)
	mockAudit.AssertExpectations(t)
}

// Test ValidateToken - Valid token
func TestValidateToken_Valid(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	user := &entity.User{
		ID:       "user-123",
		Username: "john.doe",
		Email:    "john@example.com",
	}

	// Generate a valid token
	token, _, _ := service.generateAccessToken(user, []string{"analyst"}, []string{"gateway:read"})

	// Validate the token
	claims, err := service.ValidateToken(token)

	assert.NoError(t, err)
	assert.NotNil(t, claims)
	assert.Equal(t, user.ID, claims.UserID)
	assert.Equal(t, user.Username, claims.Username)
	assert.Contains(t, claims.Roles, "analyst")
	assert.Contains(t, claims.Permissions, "gateway:read")
}

// Test ValidateToken - Invalid token
func TestValidateToken_Invalid(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	invalidToken := "invalid.token.string"

	claims, err := service.ValidateToken(invalidToken)

	assert.Error(t, err)
	assert.Nil(t, claims)
}

// Test ChangePassword - Success
func TestChangePassword_Success(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	ctx := context.Background()
	userID := "user-123"
	oldPassword := "OldPassword123!"
	newPassword := "NewPassword456@"
	passwordHash, _ := bcrypt.GenerateFromPassword([]byte(oldPassword), bcrypt.DefaultCost)

	user := &entity.User{
		ID:           userID,
		Username:     "john.doe",
		PasswordHash: string(passwordHash),
	}

	mockRepo.On("GetUserByID", ctx, userID).Return(user, nil)
	mockRepo.On("CheckPasswordHistory", ctx, userID, newPassword).Return(nil)
	mockRepo.On("UpdatePassword", ctx, userID, mock.AnythingOfType("string")).Return(nil)
	mockRepo.On("AddPasswordHistory", ctx, userID, mock.AnythingOfType("string")).Return(nil)
	mockRepo.On("RevokeAllUserTokens", ctx, userID).Return(nil)

	err := service.ChangePassword(ctx, userID, oldPassword, newPassword)

	assert.NoError(t, err)
	mockRepo.AssertExpectations(t)
}

// Test ChangePassword - Invalid old password
func TestChangePassword_InvalidOldPassword(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	ctx := context.Background()
	userID := "user-123"
	oldPassword := "OldPassword123!"
	wrongOldPassword := "WrongOldPassword"
	newPassword := "NewPassword456@"
	passwordHash, _ := bcrypt.GenerateFromPassword([]byte(oldPassword), bcrypt.DefaultCost)

	user := &entity.User{
		ID:           userID,
		Username:     "john.doe",
		PasswordHash: string(passwordHash),
	}

	mockRepo.On("GetUserByID", ctx, userID).Return(user, nil)

	err := service.ChangePassword(ctx, userID, wrongOldPassword, newPassword)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "invalid old password")
	mockRepo.AssertExpectations(t)
}

// Test ChangePassword - Weak new password
func TestChangePassword_WeakPassword(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	ctx := context.Background()
	userID := "user-123"
	oldPassword := "OldPassword123!"
	weakPassword := "weak"
	passwordHash, _ := bcrypt.GenerateFromPassword([]byte(oldPassword), bcrypt.DefaultCost)

	user := &entity.User{
		ID:           userID,
		Username:     "john.doe",
		PasswordHash: string(passwordHash),
	}

	mockRepo.On("GetUserByID", ctx, userID).Return(user, nil)

	err := service.ChangePassword(ctx, userID, oldPassword, weakPassword)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "at least 12 characters")
	mockRepo.AssertExpectations(t)
}

// Test validatePassword - All requirements met
func TestValidatePassword_AllRequirements(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	err := service.validatePassword("StrongPass123!")

	assert.NoError(t, err)
}

// Test validatePassword - Too short
func TestValidatePassword_TooShort(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	err := service.validatePassword("Short1!")

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "at least 12 characters")
}

// Test validatePassword - Missing uppercase
func TestValidatePassword_MissingUppercase(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	err := service.validatePassword("weakpassword123!")

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "uppercase letter")
}

// Test validatePassword - Missing number
func TestValidatePassword_MissingNumber(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	err := service.validatePassword("WeakPassword!")

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "number")
}

// Test validatePassword - Missing special character
func TestValidatePassword_MissingSpecial(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	mockVault := new(MockVaultClient)
	logger := zap.NewNop()

	config := AuthServiceConfig{
		GenerateKeysIfEmpty: true,
	}

	service, _ := NewAuthService(mockRepo, mockAudit, mockVault, logger, config)

	err := service.validatePassword("WeakPassword123")

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "special character")
}
