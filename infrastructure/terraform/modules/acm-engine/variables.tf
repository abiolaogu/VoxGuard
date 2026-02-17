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

variable "replicas" {
  description = "Detection engine replicas"
  type        = number
}

variable "min_replicas" {
  description = "Minimum replicas"
  type        = number
}

variable "max_replicas" {
  description = "Maximum replicas"
  type        = number
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
}

variable "memory_request" {
  description = "Memory request"
  type        = string
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
}

variable "yugabyte_endpoints" {
  description = "Yugabyte endpoints"
  type        = any
}

variable "dragonfly_endpoints" {
  description = "Dragonfly endpoints"
  type        = any
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
