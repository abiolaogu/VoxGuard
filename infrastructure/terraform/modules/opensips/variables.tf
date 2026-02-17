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
  description = "OpenSIPS replica count"
  type        = number
}

variable "min_replicas" {
  description = "OpenSIPS minimum replicas"
  type        = number
}

variable "max_replicas" {
  description = "OpenSIPS maximum replicas"
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

variable "workers" {
  description = "OpenSIPS worker count"
  type        = number
}

variable "max_tcp_connections" {
  description = "Maximum TCP connections"
  type        = number
}

variable "circuit_breaker_config" {
  description = "Circuit breaker configuration"
  type = object({
    failure_threshold = number
    timeout_seconds   = number
    success_threshold = number
  })
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

variable "enable_load_balancer" {
  description = "Enable load balancer"
  type        = bool
  default     = true
}

variable "lb_type" {
  description = "Load balancer type"
  type        = string
  default     = "internal"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
