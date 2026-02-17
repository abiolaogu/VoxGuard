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

variable "enable_geo_distribution" {
  description = "Enable geo-distribution"
  type        = bool
  default     = true
}

variable "replication_factor" {
  description = "Replication factor"
  type        = number
}

variable "placement_zones" {
  description = "Placement zones"
  type        = list(string)
}

variable "preferred_leaders" {
  description = "Preferred leader regions"
  type        = list(string)
}

variable "tserver_cpu_cores" {
  description = "YB TServer CPU cores"
  type        = number
}

variable "tserver_memory_gb" {
  description = "YB TServer memory in GB"
  type        = number
}

variable "master_cpu_cores" {
  description = "YB Master CPU cores"
  type        = number
}

variable "master_memory_gb" {
  description = "YB Master memory in GB"
  type        = number
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
}

variable "disk_type" {
  description = "Disk type"
  type        = string
}

variable "tserver_replicas" {
  description = "TServer replica count"
  type        = number
}

variable "master_replicas" {
  description = "Master replica count"
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
