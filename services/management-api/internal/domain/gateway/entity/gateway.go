// Package entity contains domain entities for the Gateway bounded context
package entity

import (
	"errors"
	"net"
	"time"
)

// Common domain errors
var (
	ErrInvalidIPAddress     = errors.New("invalid IP address format")
	ErrInvalidGatewayType   = errors.New("invalid gateway type")
	ErrInvalidCarrierName   = errors.New("carrier name cannot be empty")
	ErrGatewayAlreadyActive = errors.New("gateway is already active")
	ErrGatewayNotActive     = errors.New("gateway is not active")
	ErrGatewayBlacklisted   = errors.New("gateway is blacklisted")
)

// GatewayType represents the type of network gateway
type GatewayType string

const (
	GatewayTypeLocal         GatewayType = "local"
	GatewayTypeInternational GatewayType = "international"
	GatewayTypeTransit       GatewayType = "transit"
)

// IsValid checks if the gateway type is valid
func (t GatewayType) IsValid() bool {
	switch t {
	case GatewayTypeLocal, GatewayTypeInternational, GatewayTypeTransit:
		return true
	}
	return false
}

// Gateway is the aggregate root for gateway management
type Gateway struct {
	id                string
	name              string
	ipAddress         net.IP
	carrierName       string
	gatewayType       GatewayType
	fraudThreshold    float64
	cpmLimit          int
	acdThreshold      float64
	isActive          bool
	isBlacklisted     bool
	blacklistReason   string
	blacklistExpiresAt *time.Time
	createdAt         time.Time
	updatedAt         time.Time
	
	// Read-only statistics (populated when needed)
	callsToday int
	fraudCount int
}

// NewGateway creates a new Gateway with validation
func NewGateway(id, name, ipAddress, carrierName string, gatewayType GatewayType) (*Gateway, error) {
	ip := net.ParseIP(ipAddress)
	if ip == nil {
		return nil, ErrInvalidIPAddress
	}
	
	if !gatewayType.IsValid() {
		return nil, ErrInvalidGatewayType
	}
	
	if carrierName == "" {
		return nil, ErrInvalidCarrierName
	}
	
	now := time.Now()
	return &Gateway{
		id:             id,
		name:           name,
		ipAddress:      ip,
		carrierName:    carrierName,
		gatewayType:    gatewayType,
		fraudThreshold: 0.8,  // Default 80%
		cpmLimit:       60,   // Default 60 CPM
		acdThreshold:   10.0, // Default 10 seconds
		isActive:       true,
		isBlacklisted:  false,
		createdAt:      now,
		updatedAt:      now,
	}, nil
}

// Reconstitute creates a Gateway from persisted data (no validation)
func Reconstitute(
	id, name string,
	ipAddress net.IP,
	carrierName string,
	gatewayType GatewayType,
	fraudThreshold float64,
	cpmLimit int,
	acdThreshold float64,
	isActive, isBlacklisted bool,
	blacklistReason string,
	blacklistExpiresAt *time.Time,
	createdAt, updatedAt time.Time,
) *Gateway {
	return &Gateway{
		id:                 id,
		name:               name,
		ipAddress:          ipAddress,
		carrierName:        carrierName,
		gatewayType:        gatewayType,
		fraudThreshold:     fraudThreshold,
		cpmLimit:           cpmLimit,
		acdThreshold:       acdThreshold,
		isActive:           isActive,
		isBlacklisted:      isBlacklisted,
		blacklistReason:    blacklistReason,
		blacklistExpiresAt: blacklistExpiresAt,
		createdAt:          createdAt,
		updatedAt:          updatedAt,
	}
}

// === Getters ===

func (g *Gateway) ID() string               { return g.id }
func (g *Gateway) Name() string             { return g.name }
func (g *Gateway) IPAddress() net.IP        { return g.ipAddress }
func (g *Gateway) CarrierName() string      { return g.carrierName }
func (g *Gateway) GatewayType() GatewayType { return g.gatewayType }
func (g *Gateway) FraudThreshold() float64  { return g.fraudThreshold }
func (g *Gateway) CPMLimit() int            { return g.cpmLimit }
func (g *Gateway) ACDThreshold() float64    { return g.acdThreshold }
func (g *Gateway) IsActive() bool           { return g.isActive }
func (g *Gateway) IsBlacklisted() bool      { return g.isBlacklisted }
func (g *Gateway) BlacklistReason() string  { return g.blacklistReason }
func (g *Gateway) CreatedAt() time.Time     { return g.createdAt }
func (g *Gateway) UpdatedAt() time.Time     { return g.updatedAt }
func (g *Gateway) CallsToday() int          { return g.callsToday }
func (g *Gateway) FraudCount() int          { return g.fraudCount }

// IsInternational returns true if this is an international gateway
func (g *Gateway) IsInternational() bool {
	return g.gatewayType == GatewayTypeInternational
}

// === Behavior ===

// UpdateThresholds modifies detection thresholds with validation
func (g *Gateway) UpdateThresholds(fraudThreshold *float64, cpmLimit *int, acdThreshold *float64) {
	if fraudThreshold != nil {
		t := *fraudThreshold
		if t < 0 {
			t = 0
		} else if t > 1 {
			t = 1
		}
		g.fraudThreshold = t
	}
	if cpmLimit != nil {
		c := *cpmLimit
		if c < 1 {
			c = 1
		} else if c > 1000 {
			c = 1000
		}
		g.cpmLimit = c
	}
	if acdThreshold != nil {
		a := *acdThreshold
		if a < 1 {
			a = 1
		}
		g.acdThreshold = a
	}
	g.updatedAt = time.Now()
}

// UpdateName changes the gateway name
func (g *Gateway) UpdateName(name string) {
	if name != "" {
		g.name = name
		g.updatedAt = time.Now()
	}
}

// UpdateCarrier changes the carrier name
func (g *Gateway) UpdateCarrier(carrierName string) {
	if carrierName != "" {
		g.carrierName = carrierName
		g.updatedAt = time.Now()
	}
}

// Activate enables the gateway
func (g *Gateway) Activate() error {
	if g.isActive {
		return ErrGatewayAlreadyActive
	}
	if g.isBlacklisted {
		return ErrGatewayBlacklisted
	}
	g.isActive = true
	g.updatedAt = time.Now()
	return nil
}

// Deactivate disables the gateway
func (g *Gateway) Deactivate() error {
	if !g.isActive {
		return ErrGatewayNotActive
	}
	g.isActive = false
	g.updatedAt = time.Now()
	return nil
}

// Blacklist adds the gateway to blacklist
func (g *Gateway) Blacklist(reason string, expiresAt *time.Time) {
	g.isBlacklisted = true
	g.blacklistReason = reason
	g.blacklistExpiresAt = expiresAt
	g.isActive = false
	g.updatedAt = time.Now()
}

// Unblacklist removes the gateway from blacklist
func (g *Gateway) Unblacklist() {
	g.isBlacklisted = false
	g.blacklistReason = ""
	g.blacklistExpiresAt = nil
	g.updatedAt = time.Now()
}

// SetStatistics sets read-only call statistics
func (g *Gateway) SetStatistics(callsToday, fraudCount int) {
	g.callsToday = callsToday
	g.fraudCount = fraudCount
}

// ExceedsCPMLimit checks if a given CPM exceeds the limit
func (g *Gateway) ExceedsCPMLimit(cpm int) bool {
	return cpm > g.cpmLimit
}

// IsACDSuspicious checks if average call duration is suspiciously low
func (g *Gateway) IsACDSuspicious(acd float64) bool {
	return acd < g.acdThreshold
}
