// Package repository implements security repository with PostgreSQL
package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/billyronks/acm-management-api/internal/domain/security/entity"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

// PostgresSecurityRepository implements SecurityRepository with PostgreSQL
type PostgresSecurityRepository struct {
	pool *pgxpool.Pool
}

// NewPostgresSecurityRepository creates a new PostgreSQL security repository
func NewPostgresSecurityRepository(pool *pgxpool.Pool) *PostgresSecurityRepository {
	return &PostgresSecurityRepository{
		pool: pool,
	}
}

// User operations

func (r *PostgresSecurityRepository) CreateUser(ctx context.Context, user *entity.User) error {
	query := `
		INSERT INTO users (
			id, username, email, password_hash, first_name, last_name,
			is_active, is_locked, mfa_enabled, mfa_secret,
			created_at, updated_at, created_by, updated_by
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
	`

	_, err := r.pool.Exec(ctx, query,
		user.ID, user.Username, user.Email, user.PasswordHash,
		user.FirstName, user.LastName, user.IsActive, user.IsLocked,
		user.MFAEnabled, user.MFASecret,
		user.CreatedAt, user.UpdatedAt, user.CreatedBy, user.UpdatedBy,
	)

	return err
}

func (r *PostgresSecurityRepository) GetUserByID(ctx context.Context, userID string) (*entity.User, error) {
	query := `
		SELECT id, username, email, password_hash, first_name, last_name,
			   is_active, is_locked, locked_until, last_login, login_attempts,
			   password_changed_at, mfa_enabled, mfa_secret,
			   created_at, updated_at, created_by, updated_by
		FROM users
		WHERE id = $1
	`

	user := &entity.User{}
	err := r.pool.QueryRow(ctx, query, userID).Scan(
		&user.ID, &user.Username, &user.Email, &user.PasswordHash,
		&user.FirstName, &user.LastName, &user.IsActive, &user.IsLocked,
		&user.LockedUntil, &user.LastLogin, &user.LoginAttempts,
		&user.PasswordChangedAt, &user.MFAEnabled, &user.MFASecret,
		&user.CreatedAt, &user.UpdatedAt, &user.CreatedBy, &user.UpdatedBy,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}

	return user, err
}

func (r *PostgresSecurityRepository) GetUserByUsername(ctx context.Context, username string) (*entity.User, error) {
	query := `
		SELECT id, username, email, password_hash, first_name, last_name,
			   is_active, is_locked, locked_until, last_login, login_attempts,
			   password_changed_at, mfa_enabled, mfa_secret,
			   created_at, updated_at, created_by, updated_by
		FROM users
		WHERE username = $1
	`

	user := &entity.User{}
	err := r.pool.QueryRow(ctx, query, username).Scan(
		&user.ID, &user.Username, &user.Email, &user.PasswordHash,
		&user.FirstName, &user.LastName, &user.IsActive, &user.IsLocked,
		&user.LockedUntil, &user.LastLogin, &user.LoginAttempts,
		&user.PasswordChangedAt, &user.MFAEnabled, &user.MFASecret,
		&user.CreatedAt, &user.UpdatedAt, &user.CreatedBy, &user.UpdatedBy,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}

	return user, err
}

func (r *PostgresSecurityRepository) GetUserByEmail(ctx context.Context, email string) (*entity.User, error) {
	query := `
		SELECT id, username, email, password_hash, first_name, last_name,
			   is_active, is_locked, locked_until, last_login, login_attempts,
			   password_changed_at, mfa_enabled, mfa_secret,
			   created_at, updated_at, created_by, updated_by
		FROM users
		WHERE email = $1
	`

	user := &entity.User{}
	err := r.pool.QueryRow(ctx, query, email).Scan(
		&user.ID, &user.Username, &user.Email, &user.PasswordHash,
		&user.FirstName, &user.LastName, &user.IsActive, &user.IsLocked,
		&user.LockedUntil, &user.LastLogin, &user.LoginAttempts,
		&user.PasswordChangedAt, &user.MFAEnabled, &user.MFASecret,
		&user.CreatedAt, &user.UpdatedAt, &user.CreatedBy, &user.UpdatedBy,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}

	return user, err
}

func (r *PostgresSecurityRepository) UpdateUser(ctx context.Context, user *entity.User) error {
	query := `
		UPDATE users SET
			email = $2, first_name = $3, last_name = $4,
			is_active = $5, updated_at = $6, updated_by = $7
		WHERE id = $1
	`

	_, err := r.pool.Exec(ctx, query,
		user.ID, user.Email, user.FirstName, user.LastName,
		user.IsActive, time.Now(), user.UpdatedBy,
	)

	return err
}

func (r *PostgresSecurityRepository) DeleteUser(ctx context.Context, userID string) error {
	query := `DELETE FROM users WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, userID)
	return err
}

func (r *PostgresSecurityRepository) ListUsers(ctx context.Context, page, pageSize int) ([]*entity.User, int, error) {
	offset := (page - 1) * pageSize

	// Get total count
	var total int
	err := r.pool.QueryRow(ctx, `SELECT COUNT(*) FROM users`).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// Get users
	query := `
		SELECT id, username, email, first_name, last_name,
			   is_active, is_locked, last_login, created_at
		FROM users
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2
	`

	rows, err := r.pool.Query(ctx, query, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	users := make([]*entity.User, 0)
	for rows.Next() {
		user := &entity.User{}
		err := rows.Scan(
			&user.ID, &user.Username, &user.Email,
			&user.FirstName, &user.LastName, &user.IsActive,
			&user.IsLocked, &user.LastLogin, &user.CreatedAt,
		)
		if err != nil {
			return nil, 0, err
		}
		users = append(users, user)
	}

	return users, total, nil
}

func (r *PostgresSecurityRepository) UpdatePassword(ctx context.Context, userID, passwordHash string) error {
	query := `
		UPDATE users SET
			password_hash = $2,
			password_changed_at = $3,
			updated_at = $3
		WHERE id = $1
	`

	_, err := r.pool.Exec(ctx, query, userID, passwordHash, time.Now())
	return err
}

func (r *PostgresSecurityRepository) UpdateLastLogin(ctx context.Context, userID string) error {
	query := `UPDATE users SET last_login = $2 WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, userID, time.Now())
	return err
}

// Account lockout operations

func (r *PostgresSecurityRepository) IncrementLoginAttempts(ctx context.Context, userID string) (int, error) {
	query := `
		UPDATE users SET login_attempts = login_attempts + 1
		WHERE id = $1
		RETURNING login_attempts
	`

	var attempts int
	err := r.pool.QueryRow(ctx, query, userID).Scan(&attempts)
	return attempts, err
}

func (r *PostgresSecurityRepository) ResetLoginAttempts(ctx context.Context, userID string) error {
	query := `UPDATE users SET login_attempts = 0 WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, userID)
	return err
}

func (r *PostgresSecurityRepository) LockUser(ctx context.Context, userID string, lockedUntil time.Time) error {
	query := `
		UPDATE users SET
			is_locked = true,
			locked_until = $2
		WHERE id = $1
	`

	_, err := r.pool.Exec(ctx, query, userID, lockedUntil)
	return err
}

func (r *PostgresSecurityRepository) UnlockUser(ctx context.Context, userID string) error {
	query := `
		UPDATE users SET
			is_locked = false,
			locked_until = NULL,
			login_attempts = 0
		WHERE id = $1
	`

	_, err := r.pool.Exec(ctx, query, userID)
	return err
}

// Password history operations

func (r *PostgresSecurityRepository) CheckPasswordHistory(ctx context.Context, userID, newPassword string) error {
	query := `
		SELECT password_hash
		FROM password_history
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT 5
	`

	rows, err := r.pool.Query(ctx, query, userID)
	if err != nil {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		var oldHash string
		if err := rows.Scan(&oldHash); err != nil {
			return err
		}

		// Check if new password matches any old password
		if err := bcrypt.CompareHashAndPassword([]byte(oldHash), []byte(newPassword)); err == nil {
			return fmt.Errorf("password was used recently")
		}
	}

	return nil
}

func (r *PostgresSecurityRepository) AddPasswordHistory(ctx context.Context, userID, passwordHash string) error {
	query := `
		INSERT INTO password_history (id, user_id, password_hash, created_at)
		VALUES (gen_random_uuid(), $1, $2, $3)
	`

	_, err := r.pool.Exec(ctx, query, userID, passwordHash, time.Now())
	return err
}

// Role operations

func (r *PostgresSecurityRepository) CreateRole(ctx context.Context, role *entity.Role) error {
	query := `
		INSERT INTO roles (
			id, name, display_name, description, is_system, is_active,
			created_at, updated_at, created_by, updated_by
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`

	_, err := r.pool.Exec(ctx, query,
		role.ID, role.Name, role.DisplayName, role.Description,
		role.IsSystem, role.IsActive, role.CreatedAt, role.UpdatedAt,
		role.CreatedBy, role.UpdatedBy,
	)

	return err
}

func (r *PostgresSecurityRepository) GetRoleByID(ctx context.Context, roleID string) (*entity.Role, error) {
	query := `
		SELECT id, name, display_name, description, is_system, is_active,
			   created_at, updated_at, created_by, updated_by
		FROM roles
		WHERE id = $1
	`

	role := &entity.Role{}
	err := r.pool.QueryRow(ctx, query, roleID).Scan(
		&role.ID, &role.Name, &role.DisplayName, &role.Description,
		&role.IsSystem, &role.IsActive, &role.CreatedAt, &role.UpdatedAt,
		&role.CreatedBy, &role.UpdatedBy,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("role not found")
	}

	return role, err
}

func (r *PostgresSecurityRepository) GetRoleByName(ctx context.Context, name string) (*entity.Role, error) {
	query := `
		SELECT id, name, display_name, description, is_system, is_active,
			   created_at, updated_at, created_by, updated_by
		FROM roles
		WHERE name = $1
	`

	role := &entity.Role{}
	err := r.pool.QueryRow(ctx, query, name).Scan(
		&role.ID, &role.Name, &role.DisplayName, &role.Description,
		&role.IsSystem, &role.IsActive, &role.CreatedAt, &role.UpdatedAt,
		&role.CreatedBy, &role.UpdatedBy,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("role not found")
	}

	return role, err
}

func (r *PostgresSecurityRepository) UpdateRole(ctx context.Context, role *entity.Role) error {
	query := `
		UPDATE roles SET
			display_name = $2, description = $3, is_active = $4,
			updated_at = $5, updated_by = $6
		WHERE id = $1
	`

	_, err := r.pool.Exec(ctx, query,
		role.ID, role.DisplayName, role.Description, role.IsActive,
		role.UpdatedAt, role.UpdatedBy,
	)

	return err
}

func (r *PostgresSecurityRepository) DeleteRole(ctx context.Context, roleID string) error {
	query := `DELETE FROM roles WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, roleID)
	return err
}

func (r *PostgresSecurityRepository) ListRoles(ctx context.Context, activeOnly bool) ([]*entity.Role, error) {
	query := `
		SELECT id, name, display_name, description, is_system, is_active,
			   created_at, updated_at, created_by, updated_by
		FROM roles
	`

	if activeOnly {
		query += ` WHERE is_active = true`
	}

	query += ` ORDER BY name`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	roles := make([]*entity.Role, 0)
	for rows.Next() {
		role := &entity.Role{}
		err := rows.Scan(
			&role.ID, &role.Name, &role.DisplayName, &role.Description,
			&role.IsSystem, &role.IsActive, &role.CreatedAt, &role.UpdatedAt,
			&role.CreatedBy, &role.UpdatedBy,
		)
		if err != nil {
			return nil, err
		}
		roles = append(roles, role)
	}

	return roles, nil
}

// User-Role operations

func (r *PostgresSecurityRepository) AssignRoleToUser(ctx context.Context, userRole *entity.UserRole) error {
	query := `
		INSERT INTO user_roles (user_id, role_id, granted_by, granted_at, expires_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (user_id, role_id) DO NOTHING
	`

	_, err := r.pool.Exec(ctx, query,
		userRole.UserID, userRole.RoleID, userRole.GrantedBy,
		userRole.GrantedAt, userRole.ExpiresAt,
	)

	return err
}

func (r *PostgresSecurityRepository) RevokeRoleFromUser(ctx context.Context, userID, roleID string) error {
	query := `DELETE FROM user_roles WHERE user_id = $1 AND role_id = $2`
	_, err := r.pool.Exec(ctx, query, userID, roleID)
	return err
}

func (r *PostgresSecurityRepository) GetUserRoles(ctx context.Context, userID string) ([]string, error) {
	query := `
		SELECT r.name
		FROM user_roles ur
		JOIN roles r ON ur.role_id = r.id
		WHERE ur.user_id = $1
			AND r.is_active = true
			AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
	`

	rows, err := r.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	roles := make([]string, 0)
	for rows.Next() {
		var role string
		if err := rows.Scan(&role); err != nil {
			return nil, err
		}
		roles = append(roles, role)
	}

	return roles, nil
}

func (r *PostgresSecurityRepository) GetUsersWithRole(ctx context.Context, roleID string) ([]*entity.User, error) {
	query := `
		SELECT u.id, u.username, u.email, u.first_name, u.last_name
		FROM users u
		JOIN user_roles ur ON u.id = ur.user_id
		WHERE ur.role_id = $1
	`

	rows, err := r.pool.Query(ctx, query, roleID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	users := make([]*entity.User, 0)
	for rows.Next() {
		user := &entity.User{}
		err := rows.Scan(&user.ID, &user.Username, &user.Email, &user.FirstName, &user.LastName)
		if err != nil {
			return nil, err
		}
		users = append(users, user)
	}

	return users, nil
}

// Permission operations

func (r *PostgresSecurityRepository) CreatePermission(ctx context.Context, permission *entity.Permission) error {
	query := `
		INSERT INTO permissions (id, resource, action, display_name, description, is_system, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		ON CONFLICT (resource, action) DO NOTHING
	`

	_, err := r.pool.Exec(ctx, query,
		permission.ID, permission.Resource, permission.Action,
		permission.DisplayName, permission.Description, permission.IsSystem,
		permission.CreatedAt,
	)

	return err
}

func (r *PostgresSecurityRepository) GetPermissionByID(ctx context.Context, permissionID string) (*entity.Permission, error) {
	query := `
		SELECT id, resource, action, display_name, description, is_system, created_at
		FROM permissions
		WHERE id = $1
	`

	permission := &entity.Permission{}
	err := r.pool.QueryRow(ctx, query, permissionID).Scan(
		&permission.ID, &permission.Resource, &permission.Action,
		&permission.DisplayName, &permission.Description, &permission.IsSystem,
		&permission.CreatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("permission not found")
	}

	return permission, err
}

func (r *PostgresSecurityRepository) ListPermissions(ctx context.Context) ([]*entity.Permission, error) {
	query := `
		SELECT id, resource, action, display_name, description, is_system, created_at
		FROM permissions
		ORDER BY resource, action
	`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	permissions := make([]*entity.Permission, 0)
	for rows.Next() {
		permission := &entity.Permission{}
		err := rows.Scan(
			&permission.ID, &permission.Resource, &permission.Action,
			&permission.DisplayName, &permission.Description, &permission.IsSystem,
			&permission.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		permissions = append(permissions, permission)
	}

	return permissions, nil
}

// Role-Permission operations

func (r *PostgresSecurityRepository) AssignPermissionToRole(ctx context.Context, roleID, permissionID, grantedBy string) error {
	query := `
		INSERT INTO role_permissions (role_id, permission_id, granted_by, granted_at)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (role_id, permission_id) DO NOTHING
	`

	_, err := r.pool.Exec(ctx, query, roleID, permissionID, grantedBy, time.Now())
	return err
}

func (r *PostgresSecurityRepository) RevokePermissionFromRole(ctx context.Context, roleID, permissionID string) error {
	query := `DELETE FROM role_permissions WHERE role_id = $1 AND permission_id = $2`
	_, err := r.pool.Exec(ctx, query, roleID, permissionID)
	return err
}

func (r *PostgresSecurityRepository) GetRolePermissions(ctx context.Context, roleID string) ([]*entity.Permission, error) {
	query := `
		SELECT p.id, p.resource, p.action, p.display_name, p.description, p.is_system, p.created_at
		FROM permissions p
		JOIN role_permissions rp ON p.id = rp.permission_id
		WHERE rp.role_id = $1
	`

	rows, err := r.pool.Query(ctx, query, roleID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	permissions := make([]*entity.Permission, 0)
	for rows.Next() {
		permission := &entity.Permission{}
		err := rows.Scan(
			&permission.ID, &permission.Resource, &permission.Action,
			&permission.DisplayName, &permission.Description, &permission.IsSystem,
			&permission.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		permissions = append(permissions, permission)
	}

	return permissions, nil
}

func (r *PostgresSecurityRepository) GetUserPermissions(ctx context.Context, userID string) ([]string, error) {
	query := `
		SELECT DISTINCT p.resource || ':' || p.action as permission
		FROM permissions p
		JOIN role_permissions rp ON p.id = rp.permission_id
		JOIN user_roles ur ON rp.role_id = ur.role_id
		WHERE ur.user_id = $1
			AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
	`

	rows, err := r.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	permissions := make([]string, 0)
	for rows.Next() {
		var permission string
		if err := rows.Scan(&permission); err != nil {
			return nil, err
		}
		permissions = append(permissions, permission)
	}

	return permissions, nil
}

// Resource Policy operations

func (r *PostgresSecurityRepository) CreateResourcePolicy(ctx context.Context, policy *entity.ResourcePolicy) error {
	query := `
		INSERT INTO resource_policies (
			id, resource, action, effect, conditions, priority, is_active,
			description, created_at, updated_at, created_by
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`

	_, err := r.pool.Exec(ctx, query,
		policy.ID, policy.Resource, policy.Action, policy.Effect,
		policy.Conditions, policy.Priority, policy.IsActive, policy.Description,
		policy.CreatedAt, policy.UpdatedAt, policy.CreatedBy,
	)

	return err
}

func (r *PostgresSecurityRepository) GetResourcePolicies(ctx context.Context, resource, action string) ([]*entity.ResourcePolicy, error) {
	query := `
		SELECT id, resource, action, effect, conditions, priority, is_active,
			   description, created_at, updated_at, created_by
		FROM resource_policies
		WHERE resource = $1 AND action = $2 AND is_active = true
		ORDER BY priority DESC
	`

	rows, err := r.pool.Query(ctx, query, resource, action)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	policies := make([]*entity.ResourcePolicy, 0)
	for rows.Next() {
		policy := &entity.ResourcePolicy{}
		err := rows.Scan(
			&policy.ID, &policy.Resource, &policy.Action, &policy.Effect,
			&policy.Conditions, &policy.Priority, &policy.IsActive,
			&policy.Description, &policy.CreatedAt, &policy.UpdatedAt,
			&policy.CreatedBy,
		)
		if err != nil {
			return nil, err
		}
		policies = append(policies, policy)
	}

	return policies, nil
}

func (r *PostgresSecurityRepository) UpdateResourcePolicy(ctx context.Context, policy *entity.ResourcePolicy) error {
	query := `
		UPDATE resource_policies SET
			effect = $2, conditions = $3, priority = $4, is_active = $5,
			description = $6, updated_at = $7
		WHERE id = $1
	`

	_, err := r.pool.Exec(ctx, query,
		policy.ID, policy.Effect, policy.Conditions, policy.Priority,
		policy.IsActive, policy.Description, time.Now(),
	)

	return err
}

func (r *PostgresSecurityRepository) DeleteResourcePolicy(ctx context.Context, policyID string) error {
	query := `DELETE FROM resource_policies WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, policyID)
	return err
}

// Refresh Token operations

func (r *PostgresSecurityRepository) CreateRefreshToken(ctx context.Context, token *entity.RefreshToken) error {
	query := `
		INSERT INTO refresh_tokens (
			id, user_id, token_hash, expires_at, is_revoked,
			created_at, ip_address, user_agent
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`

	_, err := r.pool.Exec(ctx, query,
		token.ID, token.UserID, token.TokenHash, token.ExpiresAt,
		token.IsRevoked, time.Now(), token.IPAddress, token.UserAgent,
	)

	return err
}

func (r *PostgresSecurityRepository) GetRefreshToken(ctx context.Context, tokenHash string) (*entity.RefreshToken, error) {
	query := `
		SELECT id, user_id, token_hash, expires_at, is_revoked, revoked_at,
			   created_at, last_used_at, ip_address, user_agent
		FROM refresh_tokens
		WHERE token_hash = $1
	`

	token := &entity.RefreshToken{}
	err := r.pool.QueryRow(ctx, query, tokenHash).Scan(
		&token.ID, &token.UserID, &token.TokenHash, &token.ExpiresAt,
		&token.IsRevoked, &token.RevokedAt, &token.CreatedAt,
		&token.LastUsedAt, &token.IPAddress, &token.UserAgent,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("refresh token not found")
	}

	return token, err
}

func (r *PostgresSecurityRepository) UpdateRefreshTokenLastUsed(ctx context.Context, tokenID string) error {
	query := `UPDATE refresh_tokens SET last_used_at = $2 WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, tokenID, time.Now())
	return err
}

func (r *PostgresSecurityRepository) RevokeRefreshToken(ctx context.Context, tokenHash string) error {
	query := `
		UPDATE refresh_tokens SET
			is_revoked = true,
			revoked_at = $2
		WHERE token_hash = $1
	`

	_, err := r.pool.Exec(ctx, query, tokenHash, time.Now())
	return err
}

func (r *PostgresSecurityRepository) RevokeAllUserTokens(ctx context.Context, userID string) error {
	query := `
		UPDATE refresh_tokens SET
			is_revoked = true,
			revoked_at = $2
		WHERE user_id = $1 AND is_revoked = false
	`

	_, err := r.pool.Exec(ctx, query, userID, time.Now())
	return err
}

func (r *PostgresSecurityRepository) CleanupExpiredTokens(ctx context.Context) error {
	query := `DELETE FROM refresh_tokens WHERE expires_at < NOW()`
	_, err := r.pool.Exec(ctx, query)
	return err
}

// Audit operations (immutable - append-only)

func (r *PostgresSecurityRepository) CreateAuditEvent(ctx context.Context, event *entity.AuditEvent) error {
	query := `
		INSERT INTO audit_events (
			id, timestamp, user_id, username, action, resource_type, resource_id,
			resource_name, old_values, new_values, status, severity,
			ip_address, user_agent, request_id, error_message, metadata, compliance_flags
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
	`

	_, err := r.pool.Exec(ctx, query,
		event.ID, event.Timestamp, event.UserID, event.Username, event.Action,
		event.ResourceType, event.ResourceID, event.ResourceName,
		event.OldValues, event.NewValues, event.Status, event.Severity,
		event.IPAddress, event.UserAgent, event.RequestID, event.ErrorMessage,
		event.Metadata, event.ComplianceFlags,
	)

	return err
}

func (r *PostgresSecurityRepository) QueryAuditEvents(ctx context.Context, filter entity.AuditFilter, page, pageSize int) ([]*entity.AuditEvent, int, error) {
	// Build query with filters
	whereClause := "WHERE 1=1"
	args := []interface{}{}
	argCount := 1

	if filter.UserID != "" {
		whereClause += fmt.Sprintf(" AND user_id = $%d", argCount)
		args = append(args, filter.UserID)
		argCount++
	}

	if filter.Action != "" {
		whereClause += fmt.Sprintf(" AND action = $%d", argCount)
		args = append(args, filter.Action)
		argCount++
	}

	if filter.ResourceType != "" {
		whereClause += fmt.Sprintf(" AND resource_type = $%d", argCount)
		args = append(args, filter.ResourceType)
		argCount++
	}

	if filter.Status != "" {
		whereClause += fmt.Sprintf(" AND status = $%d", argCount)
		args = append(args, filter.Status)
		argCount++
	}

	if filter.Severity != "" {
		whereClause += fmt.Sprintf(" AND severity = $%d", argCount)
		args = append(args, filter.Severity)
		argCount++
	}

	if !filter.StartTime.IsZero() {
		whereClause += fmt.Sprintf(" AND timestamp >= $%d", argCount)
		args = append(args, filter.StartTime)
		argCount++
	}

	if !filter.EndTime.IsZero() {
		whereClause += fmt.Sprintf(" AND timestamp <= $%d", argCount)
		args = append(args, filter.EndTime)
		argCount++
	}

	// Get total count
	var total int
	countQuery := "SELECT COUNT(*) FROM audit_events " + whereClause
	err := r.pool.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// Get events
	offset := (page - 1) * pageSize
	query := `
		SELECT id, timestamp, user_id, username, action, resource_type, resource_id,
			   resource_name, old_values, new_values, status, severity,
			   ip_address, user_agent, request_id, error_message, metadata
		FROM audit_events
		` + whereClause + `
		ORDER BY timestamp DESC
		LIMIT $` + fmt.Sprintf("%d", argCount) + ` OFFSET $` + fmt.Sprintf("%d", argCount+1)

	args = append(args, pageSize, offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	events := make([]*entity.AuditEvent, 0)
	for rows.Next() {
		event := &entity.AuditEvent{}
		err := rows.Scan(
			&event.ID, &event.Timestamp, &event.UserID, &event.Username,
			&event.Action, &event.ResourceType, &event.ResourceID, &event.ResourceName,
			&event.OldValues, &event.NewValues, &event.Status, &event.Severity,
			&event.IPAddress, &event.UserAgent, &event.RequestID, &event.ErrorMessage,
			&event.Metadata,
		)
		if err != nil {
			return nil, 0, err
		}
		events = append(events, event)
	}

	return events, total, nil
}

func (r *PostgresSecurityRepository) GetAuditStats(ctx context.Context, startTime, endTime time.Time) (*entity.AuditStats, error) {
	stats := &entity.AuditStats{
		EventsByAction:   make(map[string]int64),
		EventsByResource: make(map[string]int64),
		EventsBySeverity: make(map[string]int64),
	}

	// Total events
	query := `SELECT COUNT(*) FROM audit_events WHERE timestamp BETWEEN $1 AND $2`
	err := r.pool.QueryRow(ctx, query, startTime, endTime).Scan(&stats.TotalEvents)
	if err != nil {
		return nil, err
	}

	// Events by action
	query = `
		SELECT action, COUNT(*) as count
		FROM audit_events
		WHERE timestamp BETWEEN $1 AND $2
		GROUP BY action
	`
	rows, err := r.pool.Query(ctx, query, startTime, endTime)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var action string
		var count int64
		if err := rows.Scan(&action, &count); err != nil {
			return nil, err
		}
		stats.EventsByAction[action] = count
	}

	// Events by resource
	query = `
		SELECT resource_type, COUNT(*) as count
		FROM audit_events
		WHERE timestamp BETWEEN $1 AND $2
		GROUP BY resource_type
	`
	rows, err = r.pool.Query(ctx, query, startTime, endTime)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var resource string
		var count int64
		if err := rows.Scan(&resource, &count); err != nil {
			return nil, err
		}
		stats.EventsByResource[resource] = count
	}

	// Events by severity
	query = `
		SELECT severity, COUNT(*) as count
		FROM audit_events
		WHERE timestamp BETWEEN $1 AND $2
		GROUP BY severity
	`
	rows, err = r.pool.Query(ctx, query, startTime, endTime)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var severity string
		var count int64
		if err := rows.Scan(&severity, &count); err != nil {
			return nil, err
		}
		stats.EventsBySeverity[severity] = count
	}

	// Failure rate
	if stats.TotalEvents > 0 {
		var failures int64
		query = `SELECT COUNT(*) FROM audit_events WHERE timestamp BETWEEN $1 AND $2 AND status = 'failure'`
		err := r.pool.QueryRow(ctx, query, startTime, endTime).Scan(&failures)
		if err == nil {
			stats.FailureRate = float64(failures) / float64(stats.TotalEvents) * 100
		}
	}

	return stats, nil
}

// Security Event operations

func (r *PostgresSecurityRepository) CreateSecurityEvent(ctx context.Context, event *entity.SecurityEvent) error {
	query := `
		INSERT INTO security_events (
			id, event_type, user_id, severity, description,
			ip_address, user_agent, is_resolved, metadata, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`

	_, err := r.pool.Exec(ctx, query,
		event.ID, event.EventType, event.UserID, event.Severity, event.Description,
		event.IPAddress, event.UserAgent, event.IsResolved, event.Metadata, event.CreatedAt,
	)

	return err
}

func (r *PostgresSecurityRepository) GetSecurityEventByID(ctx context.Context, eventID string) (*entity.SecurityEvent, error) {
	query := `
		SELECT id, event_type, user_id, severity, description,
			   ip_address, user_agent, is_resolved, resolved_by, resolved_at,
			   resolution_note, metadata, created_at
		FROM security_events
		WHERE id = $1
	`

	event := &entity.SecurityEvent{}
	err := r.pool.QueryRow(ctx, query, eventID).Scan(
		&event.ID, &event.EventType, &event.UserID, &event.Severity, &event.Description,
		&event.IPAddress, &event.UserAgent, &event.IsResolved, &event.ResolvedBy,
		&event.ResolvedAt, &event.ResolutionNote, &event.Metadata, &event.CreatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("security event not found")
	}

	return event, err
}

func (r *PostgresSecurityRepository) QuerySecurityEvents(ctx context.Context, eventType, severity string, resolved *bool, page, pageSize int) ([]*entity.SecurityEvent, int, error) {
	whereClause := "WHERE 1=1"
	args := []interface{}{}
	argCount := 1

	if eventType != "" {
		whereClause += fmt.Sprintf(" AND event_type = $%d", argCount)
		args = append(args, eventType)
		argCount++
	}

	if severity != "" {
		whereClause += fmt.Sprintf(" AND severity = $%d", argCount)
		args = append(args, severity)
		argCount++
	}

	if resolved != nil {
		whereClause += fmt.Sprintf(" AND is_resolved = $%d", argCount)
		args = append(args, *resolved)
		argCount++
	}

	// Get total count
	var total int
	countQuery := "SELECT COUNT(*) FROM security_events " + whereClause
	err := r.pool.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// Get events
	offset := (page - 1) * pageSize
	query := `
		SELECT id, event_type, user_id, severity, description,
			   ip_address, is_resolved, created_at
		FROM security_events
		` + whereClause + `
		ORDER BY created_at DESC
		LIMIT $` + fmt.Sprintf("%d", argCount) + ` OFFSET $` + fmt.Sprintf("%d", argCount+1)

	args = append(args, pageSize, offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	events := make([]*entity.SecurityEvent, 0)
	for rows.Next() {
		event := &entity.SecurityEvent{}
		err := rows.Scan(
			&event.ID, &event.EventType, &event.UserID, &event.Severity,
			&event.Description, &event.IPAddress, &event.IsResolved, &event.CreatedAt,
		)
		if err != nil {
			return nil, 0, err
		}
		events = append(events, event)
	}

	return events, total, nil
}

func (r *PostgresSecurityRepository) UpdateSecurityEvent(ctx context.Context, event *entity.SecurityEvent) error {
	query := `
		UPDATE security_events SET
			is_resolved = $2, resolved_by = $3, resolved_at = $4, resolution_note = $5
		WHERE id = $1
	`

	_, err := r.pool.Exec(ctx, query,
		event.ID, event.IsResolved, event.ResolvedBy, event.ResolvedAt, event.ResolutionNote,
	)

	return err
}

// API Key operations

func (r *PostgresSecurityRepository) CreateAPIKey(ctx context.Context, apiKey *entity.APIKey) error {
	query := `
		INSERT INTO api_keys (
			id, name, key_hash, prefix, user_id, scopes, expires_at,
			is_active, created_at, created_by
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`

	scopesJSON, _ := json.Marshal(apiKey.Scopes)

	_, err := r.pool.Exec(ctx, query,
		apiKey.ID, apiKey.Name, apiKey.KeyHash, apiKey.Prefix, apiKey.UserID,
		string(scopesJSON), apiKey.ExpiresAt, apiKey.IsActive, apiKey.CreatedAt, apiKey.CreatedBy,
	)

	return err
}

func (r *PostgresSecurityRepository) GetAPIKeyByHash(ctx context.Context, keyHash string) (*entity.APIKey, error) {
	query := `
		SELECT id, name, key_hash, prefix, user_id, scopes, expires_at,
			   is_active, last_used_at, last_used_ip, created_at, created_by
		FROM api_keys
		WHERE key_hash = $1
	`

	apiKey := &entity.APIKey{}
	var scopesJSON string

	err := r.pool.QueryRow(ctx, query, keyHash).Scan(
		&apiKey.ID, &apiKey.Name, &apiKey.KeyHash, &apiKey.Prefix, &apiKey.UserID,
		&scopesJSON, &apiKey.ExpiresAt, &apiKey.IsActive, &apiKey.LastUsedAt,
		&apiKey.LastUsedIP, &apiKey.CreatedAt, &apiKey.CreatedBy,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("API key not found")
	}

	apiKey.Scopes = scopesJSON

	return apiKey, err
}

func (r *PostgresSecurityRepository) GetAPIKeyByID(ctx context.Context, keyID string) (*entity.APIKey, error) {
	query := `
		SELECT id, name, key_hash, prefix, user_id, scopes, expires_at,
			   is_active, last_used_at, last_used_ip, created_at, created_by
		FROM api_keys
		WHERE id = $1
	`

	apiKey := &entity.APIKey{}
	var scopesJSON string

	err := r.pool.QueryRow(ctx, query, keyID).Scan(
		&apiKey.ID, &apiKey.Name, &apiKey.KeyHash, &apiKey.Prefix, &apiKey.UserID,
		&scopesJSON, &apiKey.ExpiresAt, &apiKey.IsActive, &apiKey.LastUsedAt,
		&apiKey.LastUsedIP, &apiKey.CreatedAt, &apiKey.CreatedBy,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("API key not found")
	}

	apiKey.Scopes = scopesJSON

	return apiKey, err
}

func (r *PostgresSecurityRepository) ListUserAPIKeys(ctx context.Context, userID string) ([]*entity.APIKey, error) {
	query := `
		SELECT id, name, prefix, expires_at, is_active, last_used_at, created_at
		FROM api_keys
		WHERE user_id = $1
		ORDER BY created_at DESC
	`

	rows, err := r.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	keys := make([]*entity.APIKey, 0)
	for rows.Next() {
		key := &entity.APIKey{}
		err := rows.Scan(
			&key.ID, &key.Name, &key.Prefix, &key.ExpiresAt,
			&key.IsActive, &key.LastUsedAt, &key.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		keys = append(keys, key)
	}

	return keys, nil
}

func (r *PostgresSecurityRepository) UpdateAPIKeyLastUsed(ctx context.Context, keyID, ipAddress string) error {
	query := `
		UPDATE api_keys SET
			last_used_at = $2,
			last_used_ip = $3
		WHERE id = $1
	`

	_, err := r.pool.Exec(ctx, query, keyID, time.Now(), ipAddress)
	return err
}

func (r *PostgresSecurityRepository) RevokeAPIKey(ctx context.Context, keyID string) error {
	query := `UPDATE api_keys SET is_active = false WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, keyID)
	return err
}
