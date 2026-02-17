package service

import (
	"context"

	"github.com/billyronks/acm-management-api/internal/domain/security/entity"
)

// AuditLogger defines the minimal audit contract used by security services.
type AuditLogger interface {
	LogEvent(ctx context.Context, event entity.AuditEvent) error
	LogAuthEvent(ctx context.Context, userID, username, action, ipAddress, userAgent string, success bool, errorMsg string)
}
