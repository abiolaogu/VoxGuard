// Package repository defines the security repository interface
package repository

import (
	"context"
	"time"

	"github.com/billyronks/acm-management-api/internal/domain/security/entity"
)

// SecurityRepository defines the interface for security-related persistence
type SecurityRepository interface {
	// User operations
	CreateUser(ctx context.Context, user *entity.User) error
	GetUserByID(ctx context.Context, userID string) (*entity.User, error)
	GetUserByUsername(ctx context.Context, username string) (*entity.User, error)
	GetUserByEmail(ctx context.Context, email string) (*entity.User, error)
	UpdateUser(ctx context.Context, user *entity.User) error
	DeleteUser(ctx context.Context, userID string) error
	ListUsers(ctx context.Context, page, pageSize int) ([]*entity.User, int, error)
	UpdatePassword(ctx context.Context, userID, passwordHash string) error
	UpdateLastLogin(ctx context.Context, userID string) error

	// Account lockout
	IncrementLoginAttempts(ctx context.Context, userID string) (int, error)
	ResetLoginAttempts(ctx context.Context, userID string) error
	LockUser(ctx context.Context, userID string, lockedUntil time.Time) error
	UnlockUser(ctx context.Context, userID string) error

	// Password history
	CheckPasswordHistory(ctx context.Context, userID, passwordHash string) error
	AddPasswordHistory(ctx context.Context, userID, passwordHash string) error

	// Role operations
	CreateRole(ctx context.Context, role *entity.Role) error
	GetRoleByID(ctx context.Context, roleID string) (*entity.Role, error)
	GetRoleByName(ctx context.Context, name string) (*entity.Role, error)
	UpdateRole(ctx context.Context, role *entity.Role) error
	DeleteRole(ctx context.Context, roleID string) error
	ListRoles(ctx context.Context, activeOnly bool) ([]*entity.Role, error)

	// User-Role operations
	AssignRoleToUser(ctx context.Context, userRole *entity.UserRole) error
	RevokeRoleFromUser(ctx context.Context, userID, roleID string) error
	GetUserRoles(ctx context.Context, userID string) ([]string, error)
	GetUsersWithRole(ctx context.Context, roleID string) ([]*entity.User, error)

	// Permission operations
	CreatePermission(ctx context.Context, permission *entity.Permission) error
	GetPermissionByID(ctx context.Context, permissionID string) (*entity.Permission, error)
	ListPermissions(ctx context.Context) ([]*entity.Permission, error)

	// Role-Permission operations
	AssignPermissionToRole(ctx context.Context, roleID, permissionID, grantedBy string) error
	RevokePermissionFromRole(ctx context.Context, roleID, permissionID string) error
	GetRolePermissions(ctx context.Context, roleID string) ([]*entity.Permission, error)
	GetUserPermissions(ctx context.Context, userID string) ([]string, error)

	// Resource Policy operations
	CreateResourcePolicy(ctx context.Context, policy *entity.ResourcePolicy) error
	GetResourcePolicies(ctx context.Context, resource, action string) ([]*entity.ResourcePolicy, error)
	UpdateResourcePolicy(ctx context.Context, policy *entity.ResourcePolicy) error
	DeleteResourcePolicy(ctx context.Context, policyID string) error

	// Refresh Token operations
	CreateRefreshToken(ctx context.Context, token *entity.RefreshToken) error
	GetRefreshToken(ctx context.Context, tokenHash string) (*entity.RefreshToken, error)
	UpdateRefreshTokenLastUsed(ctx context.Context, tokenID string) error
	RevokeRefreshToken(ctx context.Context, tokenHash string) error
	RevokeAllUserTokens(ctx context.Context, userID string) error
	CleanupExpiredTokens(ctx context.Context) error

	// Audit operations (immutable)
	CreateAuditEvent(ctx context.Context, event *entity.AuditEvent) error
	QueryAuditEvents(ctx context.Context, filter entity.AuditFilter, page, pageSize int) ([]*entity.AuditEvent, int, error)
	GetAuditStats(ctx context.Context, startTime, endTime time.Time) (*entity.AuditStats, error)

	// Security Event operations
	CreateSecurityEvent(ctx context.Context, event *entity.SecurityEvent) error
	GetSecurityEventByID(ctx context.Context, eventID string) (*entity.SecurityEvent, error)
	QuerySecurityEvents(ctx context.Context, eventType, severity string, resolved *bool, page, pageSize int) ([]*entity.SecurityEvent, int, error)
	UpdateSecurityEvent(ctx context.Context, event *entity.SecurityEvent) error

	// API Key operations
	CreateAPIKey(ctx context.Context, apiKey *entity.APIKey) error
	GetAPIKeyByHash(ctx context.Context, keyHash string) (*entity.APIKey, error)
	GetAPIKeyByID(ctx context.Context, keyID string) (*entity.APIKey, error)
	ListUserAPIKeys(ctx context.Context, userID string) ([]*entity.APIKey, error)
	UpdateAPIKeyLastUsed(ctx context.Context, keyID, ipAddress string) error
	RevokeAPIKey(ctx context.Context, keyID string) error
}
