// Package entity defines security domain models
package entity

import (
	"time"
)

// ================== User & Authentication Models ==================

// User represents a system user with authentication and authorization
type User struct {
	ID           string    `json:"id" db:"id"`
	Username     string    `json:"username" db:"username"`
	Email        string    `json:"email" db:"email"`
	PasswordHash string    `json:"-" db:"password_hash"`
	FirstName    string    `json:"first_name" db:"first_name"`
	LastName     string    `json:"last_name" db:"last_name"`
	IsActive     bool      `json:"is_active" db:"is_active"`
	IsLocked     bool      `json:"is_locked" db:"is_locked"`
	LockedUntil  *time.Time `json:"locked_until,omitempty" db:"locked_until"`
	LastLogin    *time.Time `json:"last_login,omitempty" db:"last_login"`
	LoginAttempts int      `json:"-" db:"login_attempts"`
	PasswordChangedAt *time.Time `json:"password_changed_at,omitempty" db:"password_changed_at"`
	MFAEnabled   bool      `json:"mfa_enabled" db:"mfa_enabled"`
	MFASecret    string    `json:"-" db:"mfa_secret"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
	CreatedBy    string    `json:"created_by" db:"created_by"`
	UpdatedBy    string    `json:"updated_by" db:"updated_by"`
}

// UserRole represents the association between users and roles
type UserRole struct {
	UserID     string    `json:"user_id" db:"user_id"`
	RoleID     string    `json:"role_id" db:"role_id"`
	GrantedBy  string    `json:"granted_by" db:"granted_by"`
	GrantedAt  time.Time `json:"granted_at" db:"granted_at"`
	ExpiresAt  *time.Time `json:"expires_at,omitempty" db:"expires_at"`
}

// LoginRequest represents authentication credentials
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
	MFACode  string `json:"mfa_code,omitempty"`
}

// LoginResponse contains authentication tokens and user info
type LoginResponse struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
	TokenType    string    `json:"token_type"`
	ExpiresAt    time.Time `json:"expires_at"`
	User         UserInfo  `json:"user"`
}

// UserInfo represents public user information
type UserInfo struct {
	ID        string   `json:"id"`
	Username  string   `json:"username"`
	Email     string   `json:"email"`
	FirstName string   `json:"first_name"`
	LastName  string   `json:"last_name"`
	Roles     []string `json:"roles"`
	Permissions []string `json:"permissions"`
}

// RefreshTokenRequest represents a token refresh request
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// JWTClaims represents JWT token claims
type JWTClaims struct {
	UserID      string   `json:"user_id"`
	Username    string   `json:"username"`
	Email       string   `json:"email"`
	Roles       []string `json:"roles"`
	Permissions []string `json:"permissions"`
	TokenType   string   `json:"token_type"` // access or refresh
	IssuedAt    int64    `json:"iat"`
	ExpiresAt   int64    `json:"exp"`
	NotBefore   int64    `json:"nbf"`
	Issuer      string   `json:"iss"`
	Subject     string   `json:"sub"`
	JTI         string   `json:"jti"` // JWT ID for token revocation
}

// RefreshToken represents a stored refresh token
type RefreshToken struct {
	ID          string    `json:"id" db:"id"`
	UserID      string    `json:"user_id" db:"user_id"`
	TokenHash   string    `json:"-" db:"token_hash"`
	ExpiresAt   time.Time `json:"expires_at" db:"expires_at"`
	IsRevoked   bool      `json:"is_revoked" db:"is_revoked"`
	RevokedAt   *time.Time `json:"revoked_at,omitempty" db:"revoked_at"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	LastUsedAt  *time.Time `json:"last_used_at,omitempty" db:"last_used_at"`
	IPAddress   string    `json:"ip_address" db:"ip_address"`
	UserAgent   string    `json:"user_agent" db:"user_agent"`
}

// ================== RBAC Models ==================

// Role represents a security role with permissions
type Role struct {
	ID          string    `json:"id" db:"id"`
	Name        string    `json:"name" db:"name"`
	DisplayName string    `json:"display_name" db:"display_name"`
	Description string    `json:"description" db:"description"`
	IsSystem    bool      `json:"is_system" db:"is_system"` // System roles cannot be deleted
	IsActive    bool      `json:"is_active" db:"is_active"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
	CreatedBy   string    `json:"created_by" db:"created_by"`
	UpdatedBy   string    `json:"updated_by" db:"updated_by"`
}

// Permission represents a fine-grained permission
type Permission struct {
	ID          string    `json:"id" db:"id"`
	Resource    string    `json:"resource" db:"resource"`     // e.g., "gateway", "fraud_alert", "user"
	Action      string    `json:"action" db:"action"`         // e.g., "read", "write", "delete", "approve"
	DisplayName string    `json:"display_name" db:"display_name"`
	Description string    `json:"description" db:"description"`
	IsSystem    bool      `json:"is_system" db:"is_system"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

// RolePermission represents the association between roles and permissions
type RolePermission struct {
	RoleID       string    `json:"role_id" db:"role_id"`
	PermissionID string    `json:"permission_id" db:"permission_id"`
	GrantedBy    string    `json:"granted_by" db:"granted_by"`
	GrantedAt    time.Time `json:"granted_at" db:"granted_at"`
}

// ResourcePolicy represents an attribute-based access control policy
type ResourcePolicy struct {
	ID          string    `json:"id" db:"id"`
	Resource    string    `json:"resource" db:"resource"`
	Action      string    `json:"action" db:"action"`
	Effect      string    `json:"effect" db:"effect"` // allow or deny
	Conditions  string    `json:"conditions" db:"conditions"` // JSON conditions
	Priority    int       `json:"priority" db:"priority"`
	IsActive    bool      `json:"is_active" db:"is_active"`
	Description string    `json:"description" db:"description"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
	CreatedBy   string    `json:"created_by" db:"created_by"`
}

// AccessCheck represents an authorization check request
type AccessCheck struct {
	UserID   string            `json:"user_id"`
	Resource string            `json:"resource"`
	Action   string            `json:"action"`
	Context  map[string]interface{} `json:"context,omitempty"`
}

// AccessResult represents the result of an authorization check
type AccessResult struct {
	Allowed bool   `json:"allowed"`
	Reason  string `json:"reason,omitempty"`
	Policy  string `json:"policy,omitempty"`
}

// ================== Audit Models ==================

// AuditEvent represents an immutable audit log entry
type AuditEvent struct {
	ID              string    `json:"id" db:"id"`
	Timestamp       time.Time `json:"timestamp" db:"timestamp"`
	UserID          string    `json:"user_id" db:"user_id"`
	Username        string    `json:"username" db:"username"`
	Action          string    `json:"action" db:"action"`           // login, create, update, delete, etc.
	ResourceType    string    `json:"resource_type" db:"resource_type"`
	ResourceID      string    `json:"resource_id" db:"resource_id"`
	ResourceName    string    `json:"resource_name" db:"resource_name"`
	OldValues       string    `json:"old_values,omitempty" db:"old_values"` // JSON
	NewValues       string    `json:"new_values,omitempty" db:"new_values"` // JSON
	Status          string    `json:"status" db:"status"` // success, failure
	Severity        string    `json:"severity" db:"severity"` // low, medium, high, critical
	IPAddress       string    `json:"ip_address" db:"ip_address"`
	UserAgent       string    `json:"user_agent" db:"user_agent"`
	RequestID       string    `json:"request_id" db:"request_id"`
	ErrorMessage    string    `json:"error_message,omitempty" db:"error_message"`
	Metadata        string    `json:"metadata,omitempty" db:"metadata"` // JSON
	ComplianceFlags string    `json:"compliance_flags" db:"compliance_flags"` // For NCC compliance tagging
}

// AuditFilter represents filters for audit log queries
type AuditFilter struct {
	UserID       string
	Action       string
	ResourceType string
	ResourceID   string
	Status       string
	Severity     string
	StartTime    time.Time
	EndTime      time.Time
	IPAddress    string
	SearchTerm   string
}

// AuditStats represents audit statistics
type AuditStats struct {
	TotalEvents      int64            `json:"total_events"`
	EventsByAction   map[string]int64 `json:"events_by_action"`
	EventsByResource map[string]int64 `json:"events_by_resource"`
	EventsBySeverity map[string]int64 `json:"events_by_severity"`
	FailureRate      float64          `json:"failure_rate"`
	Period           string           `json:"period"`
	GeneratedAt      time.Time        `json:"generated_at"`
}

// SecurityEvent represents a security-relevant event
type SecurityEvent struct {
	ID             string    `json:"id" db:"id"`
	EventType      string    `json:"event_type" db:"event_type"` // login_failure, password_change, mfa_enabled, etc.
	UserID         string    `json:"user_id" db:"user_id"`
	Severity       string    `json:"severity" db:"severity"`
	Description    string    `json:"description" db:"description"`
	IPAddress      string    `json:"ip_address" db:"ip_address"`
	UserAgent      string    `json:"user_agent" db:"user_agent"`
	IsResolved     bool      `json:"is_resolved" db:"is_resolved"`
	ResolvedBy     *string   `json:"resolved_by,omitempty" db:"resolved_by"`
	ResolvedAt     *time.Time `json:"resolved_at,omitempty" db:"resolved_at"`
	ResolutionNote *string   `json:"resolution_note,omitempty" db:"resolution_note"`
	Metadata       string    `json:"metadata,omitempty" db:"metadata"`
	CreatedAt      time.Time `json:"created_at" db:"created_at"`
}

// ================== Password Policy Models ==================

// PasswordPolicy represents password requirements
type PasswordPolicy struct {
	MinLength          int  `json:"min_length"`
	RequireUppercase   bool `json:"require_uppercase"`
	RequireLowercase   bool `json:"require_lowercase"`
	RequireNumber      bool `json:"require_number"`
	RequireSpecial     bool `json:"require_special"`
	MaxAge             int  `json:"max_age_days"`
	HistoryCount       int  `json:"history_count"`
	LockoutThreshold   int  `json:"lockout_threshold"`
	LockoutDuration    int  `json:"lockout_duration_minutes"`
}

// PasswordHistory tracks previous passwords
type PasswordHistory struct {
	ID           string    `json:"id" db:"id"`
	UserID       string    `json:"user_id" db:"user_id"`
	PasswordHash string    `json:"-" db:"password_hash"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}

// ================== API Key Models ==================

// APIKey represents a service account API key
type APIKey struct {
	ID          string    `json:"id" db:"id"`
	Name        string    `json:"name" db:"name"`
	KeyHash     string    `json:"-" db:"key_hash"`
	Prefix      string    `json:"prefix" db:"prefix"` // First 8 chars for identification
	UserID      string    `json:"user_id" db:"user_id"`
	Scopes      string    `json:"scopes" db:"scopes"` // JSON array of scopes
	ExpiresAt   *time.Time `json:"expires_at,omitempty" db:"expires_at"`
	IsActive    bool      `json:"is_active" db:"is_active"`
	LastUsedAt  *time.Time `json:"last_used_at,omitempty" db:"last_used_at"`
	LastUsedIP  string    `json:"last_used_ip" db:"last_used_ip"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	CreatedBy   string    `json:"created_by" db:"created_by"`
}

// CreateAPIKeyRequest represents a new API key request
type CreateAPIKeyRequest struct {
	Name      string   `json:"name" binding:"required"`
	Scopes    []string `json:"scopes" binding:"required"`
	ExpiresAt *time.Time `json:"expires_at,omitempty"`
}

// CreateAPIKeyResponse contains the generated API key (only shown once)
type CreateAPIKeyResponse struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	APIKey    string    `json:"api_key"` // Only returned on creation
	ExpiresAt *time.Time `json:"expires_at,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

// ================== Request/Response Models ==================

// CreateUserRequest represents a new user creation request
type CreateUserRequest struct {
	Username  string   `json:"username" binding:"required,min=3,max=50"`
	Email     string   `json:"email" binding:"required,email"`
	Password  string   `json:"password" binding:"required,min=12"`
	FirstName string   `json:"first_name" binding:"required"`
	LastName  string   `json:"last_name" binding:"required"`
	Roles     []string `json:"roles,omitempty"`
}

// UpdateUserRequest represents user update fields
type UpdateUserRequest struct {
	Email     *string `json:"email,omitempty" binding:"omitempty,email"`
	FirstName *string `json:"first_name,omitempty"`
	LastName  *string `json:"last_name,omitempty"`
	IsActive  *bool   `json:"is_active,omitempty"`
}

// ChangePasswordRequest represents a password change request
type ChangePasswordRequest struct {
	OldPassword string `json:"old_password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=12"`
}

// ResetPasswordRequest represents a password reset request
type ResetPasswordRequest struct {
	UserID      string `json:"user_id" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=12"`
}

// CreateRoleRequest represents a new role creation request
type CreateRoleRequest struct {
	Name        string   `json:"name" binding:"required,min=3,max=50"`
	DisplayName string   `json:"display_name" binding:"required"`
	Description string   `json:"description"`
	Permissions []string `json:"permissions,omitempty"`
}

// UpdateRoleRequest represents role update fields
type UpdateRoleRequest struct {
	DisplayName *string `json:"display_name,omitempty"`
	Description *string `json:"description,omitempty"`
	IsActive    *bool   `json:"is_active,omitempty"`
}

// AssignRoleRequest represents a role assignment
type AssignRoleRequest struct {
	RoleID    string     `json:"role_id" binding:"required"`
	ExpiresAt *time.Time `json:"expires_at,omitempty"`
}

// RevokeRoleRequest represents a role revocation
type RevokeRoleRequest struct {
	RoleID string `json:"role_id" binding:"required"`
}

// Constants for predefined system roles
const (
	RoleSuperAdmin = "superadmin"
	RoleAdmin      = "admin"
	RoleOperator   = "operator"
	RoleAnalyst    = "analyst"
	RoleAuditor    = "auditor"
	RoleReadOnly   = "readonly"
)

// Constants for resource types
const (
	ResourceGateway    = "gateway"
	ResourceFraudAlert = "fraud_alert"
	ResourceUser       = "user"
	ResourceRole       = "role"
	ResourceCompliance = "compliance"
	ResourceReport     = "report"
	ResourceAPIKey     = "api_key"
	ResourceAudit      = "audit"
)

// Constants for actions
const (
	ActionRead    = "read"
	ActionWrite   = "write"
	ActionCreate  = "create"
	ActionUpdate  = "update"
	ActionDelete  = "delete"
	ActionApprove = "approve"
	ActionExport  = "export"
	ActionExecute = "execute"
)

// Constants for audit severities
const (
	SeverityLow      = "low"
	SeverityMedium   = "medium"
	SeverityHigh     = "high"
	SeverityCritical = "critical"
)

// Constants for audit statuses
const (
	StatusSuccess = "success"
	StatusFailure = "failure"
)
