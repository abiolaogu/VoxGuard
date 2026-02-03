# VoxGuard Multi-Region Deployment Variables

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "vpc_cidrs" {
  description = "VPC CIDR blocks for each region"
  type        = map(string)
  default = {
    lagos = "10.0.0.0/16"
    abuja = "10.1.0.0/16"
    asaba = "10.2.0.0/16"
  }
}

variable "circuit_breaker_config" {
  description = "Circuit breaker configuration"
  type = object({
    failure_threshold = number
    timeout_seconds   = number
    success_threshold = number
  })
  default = {
    failure_threshold = 5
    timeout_seconds   = 30
    success_threshold = 2
  }
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = ""  # Override via environment variable or tfvars file
}

variable "enable_auto_scaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = true
}

variable "enable_pod_disruption_budget" {
  description = "Enable pod disruption budgets for high availability"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Enable Kubernetes network policies"
  type        = bool
  default     = true
}

variable "tls_certificate_arn" {
  description = "ARN of TLS certificate for load balancers"
  type        = string
  default     = ""
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "enable_disaster_recovery" {
  description = "Enable disaster recovery features"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for critical alerts"
  type        = string
  default     = "ops@voxguard.ng"
}

variable "alert_slack_webhook" {
  description = "Slack webhook URL for alerts"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_audit_logging" {
  description = "Enable audit logging for compliance"
  type        = bool
  default     = true
}

variable "data_residency_region" {
  description = "Primary data residency region (for compliance)"
  type        = string
  default     = "lagos"
}

variable "enable_encryption_at_rest" {
  description = "Enable encryption at rest for databases"
  type        = bool
  default     = true
}

variable "enable_encryption_in_transit" {
  description = "Enable TLS for all inter-service communication"
  type        = bool
  default     = true
}
