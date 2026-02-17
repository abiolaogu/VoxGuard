// Package service provides security business logic
package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/billyronks/acm-management-api/internal/domain/security/entity"
	"github.com/billyronks/acm-management-api/internal/domain/security/repository"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// RBACService handles role-based access control
type RBACService struct {
	repo         repository.SecurityRepository
	auditService AuditLogger
	logger       *zap.Logger
}

// NewRBACService creates a new RBAC service
func NewRBACService(
	repo repository.SecurityRepository,
	auditService AuditLogger,
	logger *zap.Logger,
) *RBACService {
	return &RBACService{
		repo:         repo,
		auditService: auditService,
		logger:       logger,
	}
}

// CheckAccess checks if a user has permission to perform an action on a resource
func (s *RBACService) CheckAccess(ctx context.Context, check entity.AccessCheck) (*entity.AccessResult, error) {
	// Get user's roles
	roles, err := s.repo.GetUserRoles(ctx, check.UserID)
	if err != nil {
		return nil, fmt.Errorf("get user roles: %w", err)
	}

	// Superadmin has access to everything
	for _, role := range roles {
		if role == entity.RoleSuperAdmin {
			return &entity.AccessResult{
				Allowed: true,
				Reason:  "Superadmin role",
			}, nil
		}
	}

	// Get user's direct permissions
	permissions, err := s.repo.GetUserPermissions(ctx, check.UserID)
	if err != nil {
		return nil, fmt.Errorf("get user permissions: %w", err)
	}

	// Check if user has the required permission
	requiredPerm := fmt.Sprintf("%s:%s", check.Resource, check.Action)
	for _, perm := range permissions {
		if perm == requiredPerm || perm == fmt.Sprintf("%s:*", check.Resource) || perm == "*:*" {
			return &entity.AccessResult{
				Allowed: true,
				Reason:  fmt.Sprintf("Direct permission: %s", perm),
			}, nil
		}
	}

	// Check resource policies with context
	policies, err := s.repo.GetResourcePolicies(ctx, check.Resource, check.Action)
	if err != nil {
		s.logger.Error("Failed to get resource policies", zap.Error(err))
	} else {
		for _, policy := range policies {
			if !policy.IsActive {
				continue
			}

			// Evaluate policy conditions
			if s.evaluatePolicyConditions(policy.Conditions, check.Context) {
				if policy.Effect == "allow" {
					return &entity.AccessResult{
						Allowed: true,
						Reason:  fmt.Sprintf("Policy: %s", policy.Description),
						Policy:  policy.ID,
					}, nil
				} else if policy.Effect == "deny" {
					return &entity.AccessResult{
						Allowed: false,
						Reason:  fmt.Sprintf("Policy denied: %s", policy.Description),
						Policy:  policy.ID,
					}, nil
				}
			}
		}
	}

	return &entity.AccessResult{
		Allowed: false,
		Reason:  "No matching permissions or policies",
	}, nil
}

// HasPermission checks if a user has a specific permission
func (s *RBACService) HasPermission(ctx context.Context, userID, resource, action string) (bool, error) {
	result, err := s.CheckAccess(ctx, entity.AccessCheck{
		UserID:   userID,
		Resource: resource,
		Action:   action,
	})
	if err != nil {
		return false, err
	}
	return result.Allowed, nil
}

// HasRole checks if a user has a specific role
func (s *RBACService) HasRole(ctx context.Context, userID, roleName string) (bool, error) {
	roles, err := s.repo.GetUserRoles(ctx, userID)
	if err != nil {
		return false, err
	}

	for _, role := range roles {
		if role == roleName {
			return true, nil
		}
	}
	return false, nil
}

// CreateRole creates a new role with permissions
func (s *RBACService) CreateRole(ctx context.Context, req entity.CreateRoleRequest, createdBy string) (*entity.Role, error) {
	// Validate role name uniqueness
	existing, err := s.repo.GetRoleByName(ctx, req.Name)
	if err == nil && existing != nil {
		return nil, errors.New("role with this name already exists")
	}

	role := &entity.Role{
		ID:          uuid.New().String(),
		Name:        req.Name,
		DisplayName: req.DisplayName,
		Description: req.Description,
		IsSystem:    false,
		IsActive:    true,
		CreatedBy:   createdBy,
		UpdatedBy:   createdBy,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if err := s.repo.CreateRole(ctx, role); err != nil {
		return nil, fmt.Errorf("create role: %w", err)
	}

	// Assign permissions to role
	if len(req.Permissions) > 0 {
		for _, permID := range req.Permissions {
			if err := s.repo.AssignPermissionToRole(ctx, role.ID, permID, createdBy); err != nil {
				s.logger.Error("Failed to assign permission to role",
					zap.String("role_id", role.ID),
					zap.String("permission_id", permID),
					zap.Error(err))
			}
		}
	}

	// Audit log
	s.auditService.LogEvent(ctx, entity.AuditEvent{
		UserID:       createdBy,
		Action:       "create",
		ResourceType: "role",
		ResourceID:   role.ID,
		ResourceName: role.Name,
		Status:       entity.StatusSuccess,
		Severity:     entity.SeverityMedium,
	})

	return role, nil
}

// UpdateRole updates role details
func (s *RBACService) UpdateRole(ctx context.Context, roleID string, req entity.UpdateRoleRequest, updatedBy string) error {
	role, err := s.repo.GetRoleByID(ctx, roleID)
	if err != nil {
		return errors.New("role not found")
	}

	// System roles cannot be modified
	if role.IsSystem {
		return errors.New("cannot modify system role")
	}

	oldValues, _ := json.Marshal(role)

	if req.DisplayName != nil {
		role.DisplayName = *req.DisplayName
	}
	if req.Description != nil {
		role.Description = *req.Description
	}
	if req.IsActive != nil {
		role.IsActive = *req.IsActive
	}

	role.UpdatedBy = updatedBy
	role.UpdatedAt = time.Now()

	if err := s.repo.UpdateRole(ctx, role); err != nil {
		return fmt.Errorf("update role: %w", err)
	}

	newValues, _ := json.Marshal(role)

	// Audit log
	s.auditService.LogEvent(ctx, entity.AuditEvent{
		UserID:       updatedBy,
		Action:       "update",
		ResourceType: "role",
		ResourceID:   role.ID,
		ResourceName: role.Name,
		OldValues:    string(oldValues),
		NewValues:    string(newValues),
		Status:       entity.StatusSuccess,
		Severity:     entity.SeverityMedium,
	})

	return nil
}

// DeleteRole deletes a role (soft delete by deactivating)
func (s *RBACService) DeleteRole(ctx context.Context, roleID, deletedBy string) error {
	role, err := s.repo.GetRoleByID(ctx, roleID)
	if err != nil {
		return errors.New("role not found")
	}

	// System roles cannot be deleted
	if role.IsSystem {
		return errors.New("cannot delete system role")
	}

	// Check if role is assigned to any users
	users, err := s.repo.GetUsersWithRole(ctx, roleID)
	if err != nil {
		return fmt.Errorf("check role usage: %w", err)
	}

	if len(users) > 0 {
		return fmt.Errorf("cannot delete role: assigned to %d user(s)", len(users))
	}

	if err := s.repo.DeleteRole(ctx, roleID); err != nil {
		return fmt.Errorf("delete role: %w", err)
	}

	// Audit log
	s.auditService.LogEvent(ctx, entity.AuditEvent{
		UserID:       deletedBy,
		Action:       "delete",
		ResourceType: "role",
		ResourceID:   role.ID,
		ResourceName: role.Name,
		Status:       entity.StatusSuccess,
		Severity:     entity.SeverityHigh,
	})

	return nil
}

// AssignRoleToUser assigns a role to a user
func (s *RBACService) AssignRoleToUser(ctx context.Context, userID, roleID, grantedBy string, expiresAt *time.Time) error {
	// Verify role exists
	role, err := s.repo.GetRoleByID(ctx, roleID)
	if err != nil {
		return errors.New("role not found")
	}

	// Verify user exists
	user, err := s.repo.GetUserByID(ctx, userID)
	if err != nil {
		return errors.New("user not found")
	}

	// Check if user already has role
	hasRole, err := s.HasRole(ctx, userID, role.Name)
	if err != nil {
		return fmt.Errorf("check existing role: %w", err)
	}
	if hasRole {
		return errors.New("user already has this role")
	}

	userRole := &entity.UserRole{
		UserID:    userID,
		RoleID:    roleID,
		GrantedBy: grantedBy,
		GrantedAt: time.Now(),
		ExpiresAt: expiresAt,
	}

	if err := s.repo.AssignRoleToUser(ctx, userRole); err != nil {
		return fmt.Errorf("assign role: %w", err)
	}

	// Audit log
	s.auditService.LogEvent(ctx, entity.AuditEvent{
		UserID:       grantedBy,
		Action:       "assign_role",
		ResourceType: "user",
		ResourceID:   userID,
		ResourceName: user.Username,
		NewValues:    fmt.Sprintf(`{"role_id": "%s", "role_name": "%s"}`, roleID, role.Name),
		Status:       entity.StatusSuccess,
		Severity:     entity.SeverityHigh,
	})

	return nil
}

// RevokeRoleFromUser removes a role from a user
func (s *RBACService) RevokeRoleFromUser(ctx context.Context, userID, roleID, revokedBy string) error {
	// Verify user exists
	user, err := s.repo.GetUserByID(ctx, userID)
	if err != nil {
		return errors.New("user not found")
	}

	// Verify role exists
	role, err := s.repo.GetRoleByID(ctx, roleID)
	if err != nil {
		return errors.New("role not found")
	}

	if err := s.repo.RevokeRoleFromUser(ctx, userID, roleID); err != nil {
		return fmt.Errorf("revoke role: %w", err)
	}

	// Audit log
	s.auditService.LogEvent(ctx, entity.AuditEvent{
		UserID:       revokedBy,
		Action:       "revoke_role",
		ResourceType: "user",
		ResourceID:   userID,
		ResourceName: user.Username,
		OldValues:    fmt.Sprintf(`{"role_id": "%s", "role_name": "%s"}`, roleID, role.Name),
		Status:       entity.StatusSuccess,
		Severity:     entity.SeverityHigh,
	})

	return nil
}

// GetRolePermissions gets all permissions for a role
func (s *RBACService) GetRolePermissions(ctx context.Context, roleID string) ([]*entity.Permission, error) {
	return s.repo.GetRolePermissions(ctx, roleID)
}

// AssignPermissionToRole assigns a permission to a role
func (s *RBACService) AssignPermissionToRole(ctx context.Context, roleID, permissionID, grantedBy string) error {
	// Verify role exists
	role, err := s.repo.GetRoleByID(ctx, roleID)
	if err != nil {
		return errors.New("role not found")
	}

	// System roles cannot be modified
	if role.IsSystem {
		return errors.New("cannot modify system role permissions")
	}

	// Verify permission exists
	permission, err := s.repo.GetPermissionByID(ctx, permissionID)
	if err != nil {
		return errors.New("permission not found")
	}

	if err := s.repo.AssignPermissionToRole(ctx, roleID, permissionID, grantedBy); err != nil {
		return fmt.Errorf("assign permission: %w", err)
	}

	// Audit log
	s.auditService.LogEvent(ctx, entity.AuditEvent{
		UserID:       grantedBy,
		Action:       "assign_permission",
		ResourceType: "role",
		ResourceID:   roleID,
		ResourceName: role.Name,
		NewValues:    fmt.Sprintf(`{"permission_id": "%s", "permission": "%s:%s"}`, permissionID, permission.Resource, permission.Action),
		Status:       entity.StatusSuccess,
		Severity:     entity.SeverityMedium,
	})

	return nil
}

// RevokePermissionFromRole removes a permission from a role
func (s *RBACService) RevokePermissionFromRole(ctx context.Context, roleID, permissionID, revokedBy string) error {
	// Verify role exists
	role, err := s.repo.GetRoleByID(ctx, roleID)
	if err != nil {
		return errors.New("role not found")
	}

	// System roles cannot be modified
	if role.IsSystem {
		return errors.New("cannot modify system role permissions")
	}

	// Verify permission exists
	permission, err := s.repo.GetPermissionByID(ctx, permissionID)
	if err != nil {
		return errors.New("permission not found")
	}

	if err := s.repo.RevokePermissionFromRole(ctx, roleID, permissionID); err != nil {
		return fmt.Errorf("revoke permission: %w", err)
	}

	// Audit log
	s.auditService.LogEvent(ctx, entity.AuditEvent{
		UserID:       revokedBy,
		Action:       "revoke_permission",
		ResourceType: "role",
		ResourceID:   roleID,
		ResourceName: role.Name,
		OldValues:    fmt.Sprintf(`{"permission_id": "%s", "permission": "%s:%s"}`, permissionID, permission.Resource, permission.Action),
		Status:       entity.StatusSuccess,
		Severity:     entity.SeverityMedium,
	})

	return nil
}

// CreateResourcePolicy creates an attribute-based access control policy
func (s *RBACService) CreateResourcePolicy(ctx context.Context, policy *entity.ResourcePolicy, createdBy string) error {
	policy.ID = uuid.New().String()
	policy.CreatedBy = createdBy
	policy.CreatedAt = time.Now()
	policy.UpdatedAt = time.Now()

	if err := s.repo.CreateResourcePolicy(ctx, policy); err != nil {
		return fmt.Errorf("create policy: %w", err)
	}

	// Audit log
	s.auditService.LogEvent(ctx, entity.AuditEvent{
		UserID:       createdBy,
		Action:       "create",
		ResourceType: "policy",
		ResourceID:   policy.ID,
		ResourceName: policy.Description,
		Status:       entity.StatusSuccess,
		Severity:     entity.SeverityMedium,
	})

	return nil
}

// ListRoles lists all roles
func (s *RBACService) ListRoles(ctx context.Context, activeOnly bool) ([]*entity.Role, error) {
	return s.repo.ListRoles(ctx, activeOnly)
}

// ListPermissions lists all permissions
func (s *RBACService) ListPermissions(ctx context.Context) ([]*entity.Permission, error) {
	return s.repo.ListPermissions(ctx)
}

// InitializeSystemRoles creates default system roles with permissions
func (s *RBACService) InitializeSystemRoles(ctx context.Context) error {
	s.logger.Info("Initializing system roles and permissions")

	// Define permissions
	permissions := []entity.Permission{
		// Gateway permissions
		{ID: uuid.New().String(), Resource: entity.ResourceGateway, Action: entity.ActionRead, DisplayName: "View Gateways", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceGateway, Action: entity.ActionCreate, DisplayName: "Create Gateway", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceGateway, Action: entity.ActionUpdate, DisplayName: "Update Gateway", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceGateway, Action: entity.ActionDelete, DisplayName: "Delete Gateway", IsSystem: true},

		// Fraud alert permissions
		{ID: uuid.New().String(), Resource: entity.ResourceFraudAlert, Action: entity.ActionRead, DisplayName: "View Fraud Alerts", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceFraudAlert, Action: entity.ActionUpdate, DisplayName: "Update Fraud Alert", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceFraudAlert, Action: entity.ActionApprove, DisplayName: "Resolve Fraud Alert", IsSystem: true},

		// User permissions
		{ID: uuid.New().String(), Resource: entity.ResourceUser, Action: entity.ActionRead, DisplayName: "View Users", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceUser, Action: entity.ActionCreate, DisplayName: "Create User", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceUser, Action: entity.ActionUpdate, DisplayName: "Update User", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceUser, Action: entity.ActionDelete, DisplayName: "Delete User", IsSystem: true},

		// Role permissions
		{ID: uuid.New().String(), Resource: entity.ResourceRole, Action: entity.ActionRead, DisplayName: "View Roles", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceRole, Action: entity.ActionCreate, DisplayName: "Create Role", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceRole, Action: entity.ActionUpdate, DisplayName: "Update Role", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceRole, Action: entity.ActionDelete, DisplayName: "Delete Role", IsSystem: true},

		// Compliance permissions
		{ID: uuid.New().String(), Resource: entity.ResourceCompliance, Action: entity.ActionRead, DisplayName: "View Compliance Reports", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceCompliance, Action: entity.ActionCreate, DisplayName: "Create Compliance Report", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceCompliance, Action: entity.ActionExport, DisplayName: "Export Compliance Data", IsSystem: true},

		// Report permissions
		{ID: uuid.New().String(), Resource: entity.ResourceReport, Action: entity.ActionRead, DisplayName: "View Reports", IsSystem: true},
		{ID: uuid.New().String(), Resource: entity.ResourceReport, Action: entity.ActionExport, DisplayName: "Export Reports", IsSystem: true},

		// Audit permissions
		{ID: uuid.New().String(), Resource: entity.ResourceAudit, Action: entity.ActionRead, DisplayName: "View Audit Logs", IsSystem: true},
	}

	// Create permissions
	permMap := make(map[string]string) // resource:action -> permission_id
	for _, perm := range permissions {
		perm.CreatedAt = time.Now()
		if err := s.repo.CreatePermission(ctx, &perm); err != nil {
			s.logger.Error("Failed to create permission", zap.String("permission", perm.DisplayName), zap.Error(err))
		} else {
			permMap[fmt.Sprintf("%s:%s", perm.Resource, perm.Action)] = perm.ID
		}
	}

	// Define system roles with their permissions
	systemRoles := []struct {
		name        string
		displayName string
		description string
		permissions []string // resource:action format
	}{
		{
			name:        entity.RoleSuperAdmin,
			displayName: "Super Administrator",
			description: "Full system access with all permissions",
			permissions: []string{"*:*"}, // All permissions
		},
		{
			name:        entity.RoleAdmin,
			displayName: "Administrator",
			description: "Administrative access to manage users, roles, and system configuration",
			permissions: []string{
				"gateway:read", "gateway:create", "gateway:update", "gateway:delete",
				"fraud_alert:read", "fraud_alert:update", "fraud_alert:approve",
				"user:read", "user:create", "user:update",
				"role:read", "compliance:read", "report:read", "report:export",
				"audit:read",
			},
		},
		{
			name:        entity.RoleOperator,
			displayName: "Operator",
			description: "Operational access to manage gateways and fraud alerts",
			permissions: []string{
				"gateway:read", "gateway:update",
				"fraud_alert:read", "fraud_alert:update",
				"compliance:read", "report:read",
			},
		},
		{
			name:        entity.RoleAnalyst,
			displayName: "Analyst",
			description: "Analyst access to view and analyze fraud alerts and reports",
			permissions: []string{
				"gateway:read",
				"fraud_alert:read", "fraud_alert:update",
				"compliance:read", "report:read", "report:export",
			},
		},
		{
			name:        entity.RoleAuditor,
			displayName: "Auditor",
			description: "Auditor access to view audit logs and compliance reports",
			permissions: []string{
				"gateway:read",
				"fraud_alert:read",
				"compliance:read", "compliance:export",
				"report:read", "report:export",
				"audit:read",
			},
		},
		{
			name:        entity.RoleReadOnly,
			displayName: "Read Only",
			description: "Read-only access to view system data",
			permissions: []string{
				"gateway:read",
				"fraud_alert:read",
				"compliance:read",
				"report:read",
			},
		},
	}

	// Create system roles
	for _, roleData := range systemRoles {
		role := &entity.Role{
			ID:          uuid.New().String(),
			Name:        roleData.name,
			DisplayName: roleData.displayName,
			Description: roleData.description,
			IsSystem:    true,
			IsActive:    true,
			CreatedBy:   "system",
			UpdatedBy:   "system",
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
		}

		if err := s.repo.CreateRole(ctx, role); err != nil {
			s.logger.Error("Failed to create system role", zap.String("role", role.Name), zap.Error(err))
			continue
		}

		// Assign permissions to role
		for _, permKey := range roleData.permissions {
			if permID, ok := permMap[permKey]; ok {
				if err := s.repo.AssignPermissionToRole(ctx, role.ID, permID, "system"); err != nil {
					s.logger.Error("Failed to assign permission to role",
						zap.String("role", role.Name),
						zap.String("permission", permKey),
						zap.Error(err))
				}
			}
		}

		s.logger.Info("Created system role", zap.String("role", role.Name))
	}

	return nil
}

// Helper function to evaluate policy conditions
func (s *RBACService) evaluatePolicyConditions(conditionsJSON string, context map[string]interface{}) bool {
	if conditionsJSON == "" || conditionsJSON == "{}" {
		return true // No conditions means always match
	}

	var conditions map[string]interface{}
	if err := json.Unmarshal([]byte(conditionsJSON), &conditions); err != nil {
		s.logger.Error("Failed to parse policy conditions", zap.Error(err))
		return false
	}

	// Simple condition evaluation
	// Format: {"field": "value"} or {"field": {"$in": ["value1", "value2"]}}
	for key, expected := range conditions {
		actual, ok := context[key]
		if !ok {
			return false
		}

		// Handle operators
		if expectedMap, ok := expected.(map[string]interface{}); ok {
			if in, ok := expectedMap["$in"]; ok {
				if inSlice, ok := in.([]interface{}); ok {
					found := false
					for _, val := range inSlice {
						if val == actual {
							found = true
							break
						}
					}
					if !found {
						return false
					}
				}
			}
		} else if expected != actual {
			return false
		}
	}

	return true
}
