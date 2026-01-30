// Package entity contains domain entities for the MNP (Mobile Number Portability) bounded context
package entity

import (
	"errors"
	"regexp"
	"time"
)

// MNP domain errors
var (
	ErrInvalidMSISDN     = errors.New("invalid MSISDN format")
	ErrMNPRecordNotFound = errors.New("MNP record not found")
)

// Nigerian MSISDN pattern: +234 followed by 10 digits
var msisdnPattern = regexp.MustCompile(`^\+?234[0-9]{10}$`)

// PortingStatus represents the status of a porting request
type PortingStatus string

const (
	PortingStatusActive  PortingStatus = "active"
	PortingStatusPending PortingStatus = "pending"
	PortingStatusExpired PortingStatus = "expired"
)

// MNPRecord represents a Mobile Number Portability record
type MNPRecord struct {
	msisdn          string
	originalNetwork string
	currentNetwork  string
	portedDate      time.Time
	status          PortingStatus
	npcCode         string // Number Portability Clearinghouse code
	createdAt       time.Time
	updatedAt       time.Time
}

// NewMNPRecord creates a new MNP record with validation
func NewMNPRecord(msisdn, originalNetwork, currentNetwork, npcCode string) (*MNPRecord, error) {
	if !IsValidMSISDN(msisdn) {
		return nil, ErrInvalidMSISDN
	}

	now := time.Now()
	return &MNPRecord{
		msisdn:          NormalizeMSISDN(msisdn),
		originalNetwork: originalNetwork,
		currentNetwork:  currentNetwork,
		portedDate:      now,
		status:          PortingStatusActive,
		npcCode:         npcCode,
		createdAt:       now,
		updatedAt:       now,
	}, nil
}

// === Getters ===

func (r *MNPRecord) MSISDN() string          { return r.msisdn }
func (r *MNPRecord) OriginalNetwork() string { return r.originalNetwork }
func (r *MNPRecord) CurrentNetwork() string  { return r.currentNetwork }
func (r *MNPRecord) PortedDate() time.Time   { return r.portedDate }
func (r *MNPRecord) Status() PortingStatus   { return r.status }
func (r *MNPRecord) NPCCode() string         { return r.npcCode }

// IsPorted returns true if the number has been ported (current != original)
func (r *MNPRecord) IsPorted() bool {
	return r.originalNetwork != r.currentNetwork
}

// === Behavior ===

// UpdateNetwork updates the current network after a porting event
func (r *MNPRecord) UpdateNetwork(newNetwork, npcCode string) {
	r.currentNetwork = newNetwork
	r.npcCode = npcCode
	r.portedDate = time.Now()
	r.updatedAt = time.Now()
}

// === Value Objects ===

// IsValidMSISDN validates a Nigerian MSISDN format
func IsValidMSISDN(msisdn string) bool {
	return msisdnPattern.MatchString(msisdn)
}

// NormalizeMSISDN normalizes MSISDN to +234 format
func NormalizeMSISDN(msisdn string) string {
	if len(msisdn) == 0 {
		return msisdn
	}
	// Remove spaces and dashes
	cleaned := regexp.MustCompile(`[\s-]`).ReplaceAllString(msisdn, "")

	// Add + if missing
	if cleaned[0] != '+' && cleaned[0:3] == "234" {
		return "+" + cleaned
	}
	// Convert 0 prefix to +234
	if cleaned[0] == '0' && len(cleaned) == 11 {
		return "+234" + cleaned[1:]
	}
	return cleaned
}

// NetworkOperator represents a Nigerian telecom operator
type NetworkOperator struct {
	Code     string
	Name     string
	Prefixes []string
	IsActive bool
}

// GetOperatorByPrefix returns the operator for a given prefix
func GetOperatorByPrefix(prefix string) *NetworkOperator {
	operators := map[string]NetworkOperator{
		"MTN":     {Code: "MTN", Name: "MTN Nigeria", Prefixes: []string{"0803", "0806", "0703", "0706", "0813", "0816", "0814", "0903", "0906"}, IsActive: true},
		"GLO":     {Code: "GLO", Name: "Globacom", Prefixes: []string{"0805", "0807", "0705", "0815", "0811", "0905"}, IsActive: true},
		"AIRTEL":  {Code: "AIRTEL", Name: "Airtel Nigeria", Prefixes: []string{"0802", "0808", "0708", "0812", "0701", "0902", "0901", "0907"}, IsActive: true},
		"9MOBILE": {Code: "9MOBILE", Name: "9mobile", Prefixes: []string{"0809", "0818", "0817", "0909", "0908"}, IsActive: true},
	}

	for _, op := range operators {
		for _, p := range op.Prefixes {
			if prefix == p {
				return &op
			}
		}
	}
	return nil
}
