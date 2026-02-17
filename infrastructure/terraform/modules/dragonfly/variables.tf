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
  description = "Whether this region hosts the primary cluster"
  type        = bool
}

variable "enable_replication" {
  description = "Enable cross-region replication"
  type        = bool
  default     = true
}

variable "primary_region" {
  description = "Primary region name"
  type        = string
}

variable "replica_regions" {
  description = "Replica regions"
  type        = list(string)
  default     = []
}

variable "memory_limit_gb" {
  description = "Memory limit in GB"
  type        = number
}

variable "cpu_cores" {
  description = "CPU cores"
  type        = number
}

variable "replicas" {
  description = "Replica count"
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
