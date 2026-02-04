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
)

// MockSecurityRepository is a mock implementation of SecurityRepository
type MockSecurityRepository struct {
	mock.Mock
}

func (m *MockSecurityRepository) GetUserRoles(ctx context.Context, userID string) ([]string, error) {
	args := m.Called(ctx, userID)
	return args.Get(0).([]string), args.Error(1)
}

func (m *MockSecurityRepository) GetUserPermissions(ctx context.Context, userID string) ([]string, error) {
	args := m.Called(ctx, userID)
	return args.Get(0).([]string), args.Error(1)
}

func (m *MockSecurityRepository) GetResourcePolicies(ctx context.Context, resource, action string) ([]*entity.ResourcePolicy, error) {
	args := m.Called(ctx, resource, action)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*entity.ResourcePolicy), args.Error(1)
}

func (m *MockSecurityRepository) GetRoleByName(ctx context.Context, name string) (*entity.Role, error) {
	args := m.Called(ctx, name)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.Role), args.Error(1)
}

func (m *MockSecurityRepository) GetRoleByID(ctx context.Context, roleID string) (*entity.Role, error) {
	args := m.Called(ctx, roleID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.Role), args.Error(1)
}

func (m *MockSecurityRepository) CreateRole(ctx context.Context, role *entity.Role) error {
	args := m.Called(ctx, role)
	return args.Error(0)
}

func (m *MockSecurityRepository) UpdateRole(ctx context.Context, role *entity.Role) error {
	args := m.Called(ctx, role)
	return args.Error(0)
}

func (m *MockSecurityRepository) DeleteRole(ctx context.Context, roleID string) error {
	args := m.Called(ctx, roleID)
	return args.Error(0)
}

func (m *MockSecurityRepository) AssignPermissionToRole(ctx context.Context, roleID, permissionID, grantedBy string) error {
	args := m.Called(ctx, roleID, permissionID, grantedBy)
	return args.Error(0)
}

func (m *MockSecurityRepository) GetUsersWithRole(ctx context.Context, roleID string) ([]string, error) {
	args := m.Called(ctx, roleID)
	return args.Get(0).([]string), args.Error(1)
}

func (m *MockSecurityRepository) GetUserByID(ctx context.Context, userID string) (*entity.User, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.User), args.Error(1)
}

func (m *MockSecurityRepository) AssignRoleToUser(ctx context.Context, userRole *entity.UserRole) error {
	args := m.Called(ctx, userRole)
	return args.Error(0)
}

func (m *MockSecurityRepository) RevokeRoleFromUser(ctx context.Context, userID, roleID string) error {
	args := m.Called(ctx, userID, roleID)
	return args.Error(0)
}

func (m *MockSecurityRepository) GetRolePermissions(ctx context.Context, roleID string) ([]*entity.Permission, error) {
	args := m.Called(ctx, roleID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*entity.Permission), args.Error(1)
}

func (m *MockSecurityRepository) GetPermissionByID(ctx context.Context, permissionID string) (*entity.Permission, error) {
	args := m.Called(ctx, permissionID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.Permission), args.Error(1)
}

func (m *MockSecurityRepository) RevokePermissionFromRole(ctx context.Context, roleID, permissionID string) error {
	args := m.Called(ctx, roleID, permissionID)
	return args.Error(0)
}

func (m *MockSecurityRepository) CreateResourcePolicy(ctx context.Context, policy *entity.ResourcePolicy) error {
	args := m.Called(ctx, policy)
	return args.Error(0)
}

func (m *MockSecurityRepository) ListRoles(ctx context.Context, activeOnly bool) ([]*entity.Role, error) {
	args := m.Called(ctx, activeOnly)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*entity.Role), args.Error(1)
}

func (m *MockSecurityRepository) ListPermissions(ctx context.Context) ([]*entity.Permission, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*entity.Permission), args.Error(1)
}

func (m *MockSecurityRepository) CreatePermission(ctx context.Context, perm *entity.Permission) error {
	args := m.Called(ctx, perm)
	return args.Error(0)
}

func (m *MockSecurityRepository) CreateAuditEvent(ctx context.Context, event *entity.AuditEvent) error {
	args := m.Called(ctx, event)
	return args.Error(0)
}

func (m *MockSecurityRepository) GetUserByUsername(ctx context.Context, username string) (*entity.User, error) {
	args := m.Called(ctx, username)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.User), args.Error(1)
}

func (m *MockSecurityRepository) UnlockUser(ctx context.Context, userID string) error {
	args := m.Called(ctx, userID)
	return args.Error(0)
}

func (m *MockSecurityRepository) IncrementLoginAttempts(ctx context.Context, userID string) (int, error) {
	args := m.Called(ctx, userID)
	return args.Int(0), args.Error(1)
}

func (m *MockSecurityRepository) LockUser(ctx context.Context, userID string, lockUntil time.Time) error {
	args := m.Called(ctx, userID, lockUntil)
	return args.Error(0)
}

func (m *MockSecurityRepository) ResetLoginAttempts(ctx context.Context, userID string) error {
	args := m.Called(ctx, userID)
	return args.Error(0)
}

func (m *MockSecurityRepository) UpdateLastLogin(ctx context.Context, userID string) error {
	args := m.Called(ctx, userID)
	return args.Error(0)
}

func (m *MockSecurityRepository) CreateRefreshToken(ctx context.Context, token *entity.RefreshToken) error {
	args := m.Called(ctx, token)
	return args.Error(0)
}

func (m *MockSecurityRepository) GetRefreshToken(ctx context.Context, tokenHash string) (*entity.RefreshToken, error) {
	args := m.Called(ctx, tokenHash)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.RefreshToken), args.Error(1)
}

func (m *MockSecurityRepository) UpdateRefreshTokenLastUsed(ctx context.Context, tokenID string) error {
	args := m.Called(ctx, tokenID)
	return args.Error(0)
}

func (m *MockSecurityRepository) RevokeRefreshToken(ctx context.Context, tokenHash string) error {
	args := m.Called(ctx, tokenHash)
	return args.Error(0)
}

func (m *MockSecurityRepository) RevokeAllUserTokens(ctx context.Context, userID string) error {
	args := m.Called(ctx, userID)
	return args.Error(0)
}

func (m *MockSecurityRepository) UpdatePassword(ctx context.Context, userID, passwordHash string) error {
	args := m.Called(ctx, userID, passwordHash)
	return args.Error(0)
}

func (m *MockSecurityRepository) CheckPasswordHistory(ctx context.Context, userID, password string) error {
	args := m.Called(ctx, userID, password)
	return args.Error(0)
}

func (m *MockSecurityRepository) AddPasswordHistory(ctx context.Context, userID, passwordHash string) error {
	args := m.Called(ctx, userID, passwordHash)
	return args.Error(0)
}

func (m *MockSecurityRepository) QueryAuditEvents(ctx context.Context, filter entity.AuditFilter, page, pageSize int) ([]*entity.AuditEvent, int, error) {
	args := m.Called(ctx, filter, page, pageSize)
	if args.Get(0) == nil {
		return nil, args.Int(1), args.Error(2)
	}
	return args.Get(0).([]*entity.AuditEvent), args.Int(1), args.Error(2)
}

func (m *MockSecurityRepository) GetAuditStats(ctx context.Context, startTime, endTime time.Time) (*entity.AuditStats, error) {
	args := m.Called(ctx, startTime, endTime)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.AuditStats), args.Error(1)
}

func (m *MockSecurityRepository) CreateSecurityEvent(ctx context.Context, event *entity.SecurityEvent) error {
	args := m.Called(ctx, event)
	return args.Error(0)
}

func (m *MockSecurityRepository) QuerySecurityEvents(ctx context.Context, eventType, severity string, resolved *bool, page, pageSize int) ([]*entity.SecurityEvent, int, error) {
	args := m.Called(ctx, eventType, severity, resolved, page, pageSize)
	if args.Get(0) == nil {
		return nil, args.Int(1), args.Error(2)
	}
	return args.Get(0).([]*entity.SecurityEvent), args.Int(1), args.Error(2)
}

func (m *MockSecurityRepository) GetSecurityEventByID(ctx context.Context, eventID string) (*entity.SecurityEvent, error) {
	args := m.Called(ctx, eventID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.SecurityEvent), args.Error(1)
}

func (m *MockSecurityRepository) UpdateSecurityEvent(ctx context.Context, event *entity.SecurityEvent) error {
	args := m.Called(ctx, event)
	return args.Error(0)
}

// MockAuditService is a mock implementation of AuditService
type MockAuditService struct {
	mock.Mock
}

func (m *MockAuditService) LogEvent(ctx context.Context, event entity.AuditEvent) error {
	args := m.Called(ctx, event)
	return args.Error(0)
}

func (m *MockAuditService) LogAuthEvent(ctx context.Context, userID, username, action, ipAddress, userAgent string, success bool, errorMsg string) {
	m.Called(ctx, userID, username, action, ipAddress, userAgent, success, errorMsg)
}

// Test CheckAccess - Superadmin has full access
func TestCheckAccess_SuperAdmin(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	logger := zap.NewNop()

	service := NewRBACService(mockRepo, mockAudit, logger)

	ctx := context.Background()
	userID := "user-123"

	mockRepo.On("GetUserRoles", ctx, userID).Return([]string{entity.RoleSuperAdmin}, nil)

	result, err := service.CheckAccess(ctx, entity.AccessCheck{
		UserID:   userID,
		Resource: "gateway",
		Action:   "delete",
	})

	assert.NoError(t, err)
	assert.True(t, result.Allowed)
	assert.Equal(t, "Superadmin role", result.Reason)
	mockRepo.AssertExpectations(t)
}

// Test CheckAccess - User has direct permission
func TestCheckAccess_DirectPermission(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	logger := zap.NewNop()

	service := NewRBACService(mockRepo, mockAudit, logger)

	ctx := context.Background()
	userID := "user-123"

	mockRepo.On("GetUserRoles", ctx, userID).Return([]string{entity.RoleAnalyst}, nil)
	mockRepo.On("GetUserPermissions", ctx, userID).Return([]string{"gateway:read", "fraud_alert:read"}, nil)

	result, err := service.CheckAccess(ctx, entity.AccessCheck{
		UserID:   userID,
		Resource: "gateway",
		Action:   "read",
	})

	assert.NoError(t, err)
	assert.True(t, result.Allowed)
	assert.Contains(t, result.Reason, "Direct permission")
	mockRepo.AssertExpectations(t)
}

// Test CheckAccess - Access denied
func TestCheckAccess_Denied(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	logger := zap.NewNop()

	service := NewRBACService(mockRepo, mockAudit, logger)

	ctx := context.Background()
	userID := "user-123"

	mockRepo.On("GetUserRoles", ctx, userID).Return([]string{entity.RoleReadOnly}, nil)
	mockRepo.On("GetUserPermissions", ctx, userID).Return([]string{"gateway:read"}, nil)
	mockRepo.On("GetResourcePolicies", ctx, "gateway", "delete").Return([]*entity.ResourcePolicy{}, nil)

	result, err := service.CheckAccess(ctx, entity.AccessCheck{
		UserID:   userID,
		Resource: "gateway",
		Action:   "delete",
	})

	assert.NoError(t, err)
	assert.False(t, result.Allowed)
	assert.Equal(t, "No matching permissions or policies", result.Reason)
	mockRepo.AssertExpectations(t)
}

// Test CreateRole - Success
func TestCreateRole_Success(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	logger := zap.NewNop()

	service := NewRBACService(mockRepo, mockAudit, logger)

	ctx := context.Background()
	req := entity.CreateRoleRequest{
		Name:        "custom-role",
		DisplayName: "Custom Role",
		Description: "A custom role for testing",
		Permissions: []string{},
	}

	mockRepo.On("GetRoleByName", ctx, req.Name).Return(nil, errors.New("not found"))
	mockRepo.On("CreateRole", ctx, mock.AnythingOfType("*entity.Role")).Return(nil)
	mockAudit.On("LogEvent", ctx, mock.AnythingOfType("entity.AuditEvent")).Return(nil)

	role, err := service.CreateRole(ctx, req, "admin-123")

	assert.NoError(t, err)
	assert.NotNil(t, role)
	assert.Equal(t, req.Name, role.Name)
	assert.False(t, role.IsSystem)
	mockRepo.AssertExpectations(t)
	mockAudit.AssertExpectations(t)
}

// Test CreateRole - Duplicate name
func TestCreateRole_DuplicateName(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	logger := zap.NewNop()

	service := NewRBACService(mockRepo, mockAudit, logger)

	ctx := context.Background()
	req := entity.CreateRoleRequest{
		Name:        "existing-role",
		DisplayName: "Existing Role",
		Description: "A role that already exists",
	}

	existingRole := &entity.Role{ID: "role-123", Name: req.Name}
	mockRepo.On("GetRoleByName", ctx, req.Name).Return(existingRole, nil)

	role, err := service.CreateRole(ctx, req, "admin-123")

	assert.Error(t, err)
	assert.Nil(t, role)
	assert.Contains(t, err.Error(), "already exists")
	mockRepo.AssertExpectations(t)
}

// Test DeleteRole - Cannot delete system role
func TestDeleteRole_SystemRole(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	logger := zap.NewNop()

	service := NewRBACService(mockRepo, mockAudit, logger)

	ctx := context.Background()
	roleID := "role-123"

	systemRole := &entity.Role{
		ID:       roleID,
		Name:     entity.RoleSuperAdmin,
		IsSystem: true,
	}

	mockRepo.On("GetRoleByID", ctx, roleID).Return(systemRole, nil)

	err := service.DeleteRole(ctx, roleID, "admin-123")

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "cannot delete system role")
	mockRepo.AssertExpectations(t)
}

// Test DeleteRole - Role assigned to users
func TestDeleteRole_AssignedToUsers(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	logger := zap.NewNop()

	service := NewRBACService(mockRepo, mockAudit, logger)

	ctx := context.Background()
	roleID := "role-123"

	customRole := &entity.Role{
		ID:       roleID,
		Name:     "custom-role",
		IsSystem: false,
	}

	mockRepo.On("GetRoleByID", ctx, roleID).Return(customRole, nil)
	mockRepo.On("GetUsersWithRole", ctx, roleID).Return([]string{"user-1", "user-2"}, nil)

	err := service.DeleteRole(ctx, roleID, "admin-123")

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "assigned to 2 user(s)")
	mockRepo.AssertExpectations(t)
}

// Test AssignRoleToUser - Success
func TestAssignRoleToUser_Success(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	logger := zap.NewNop()

	service := NewRBACService(mockRepo, mockAudit, logger)

	ctx := context.Background()
	userID := "user-123"
	roleID := "role-456"

	role := &entity.Role{ID: roleID, Name: "analyst"}
	user := &entity.User{ID: userID, Username: "john.doe"}

	mockRepo.On("GetRoleByID", ctx, roleID).Return(role, nil)
	mockRepo.On("GetUserByID", ctx, userID).Return(user, nil)
	mockRepo.On("GetUserRoles", ctx, userID).Return([]string{}, nil)
	mockRepo.On("AssignRoleToUser", ctx, mock.AnythingOfType("*entity.UserRole")).Return(nil)
	mockAudit.On("LogEvent", ctx, mock.AnythingOfType("entity.AuditEvent")).Return(nil)

	err := service.AssignRoleToUser(ctx, userID, roleID, "admin-123", nil)

	assert.NoError(t, err)
	mockRepo.AssertExpectations(t)
	mockAudit.AssertExpectations(t)
}

// Test AssignRoleToUser - User already has role
func TestAssignRoleToUser_AlreadyHasRole(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	logger := zap.NewNop()

	service := NewRBACService(mockRepo, mockAudit, logger)

	ctx := context.Background()
	userID := "user-123"
	roleID := "role-456"

	role := &entity.Role{ID: roleID, Name: "analyst"}
	user := &entity.User{ID: userID, Username: "john.doe"}

	mockRepo.On("GetRoleByID", ctx, roleID).Return(role, nil)
	mockRepo.On("GetUserByID", ctx, userID).Return(user, nil)
	mockRepo.On("GetUserRoles", ctx, userID).Return([]string{"analyst"}, nil)

	err := service.AssignRoleToUser(ctx, userID, roleID, "admin-123", nil)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "already has this role")
	mockRepo.AssertExpectations(t)
}

// Test HasRole - User has role
func TestHasRole_True(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	logger := zap.NewNop()

	service := NewRBACService(mockRepo, mockAudit, logger)

	ctx := context.Background()
	userID := "user-123"

	mockRepo.On("GetUserRoles", ctx, userID).Return([]string{"analyst", "operator"}, nil)

	hasRole, err := service.HasRole(ctx, userID, "analyst")

	assert.NoError(t, err)
	assert.True(t, hasRole)
	mockRepo.AssertExpectations(t)
}

// Test HasRole - User does not have role
func TestHasRole_False(t *testing.T) {
	mockRepo := new(MockSecurityRepository)
	mockAudit := new(MockAuditService)
	logger := zap.NewNop()

	service := NewRBACService(mockRepo, mockAudit, logger)

	ctx := context.Background()
	userID := "user-123"

	mockRepo.On("GetUserRoles", ctx, userID).Return([]string{"analyst"}, nil)

	hasRole, err := service.HasRole(ctx, userID, "admin")

	assert.NoError(t, err)
	assert.False(t, hasRole)
	mockRepo.AssertExpectations(t)
}
