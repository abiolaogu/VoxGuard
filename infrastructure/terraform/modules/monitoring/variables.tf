variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  description = "Deployment region"
  type        = string
}

variable "is_primary" {
  description = "Whether this region is primary"
  type        = bool
}

variable "enable_prometheus" {
  description = "Enable Prometheus"
  type        = bool
}

variable "prometheus_retention_days" {
  description = "Prometheus retention days"
  type        = number
}

variable "prometheus_storage_gb" {
  description = "Prometheus storage size"
  type        = number
}

variable "enable_grafana" {
  description = "Enable Grafana"
  type        = bool
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "enable_tempo" {
  description = "Enable Tempo"
  type        = bool
}

variable "tempo_retention_days" {
  description = "Tempo retention days"
  type        = number
}

variable "tempo_storage_gb" {
  description = "Tempo storage size"
  type        = number
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
