variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "regions" {
  description = "Regional endpoint configuration"
  type = map(object({
    opensips_endpoints = list(string)
    weight             = number
    is_primary         = bool
  }))
}

variable "health_check_interval" {
  description = "Health check interval"
  type        = string
}

variable "health_check_timeout" {
  description = "Health check timeout"
  type        = string
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
}

variable "enable_session_affinity" {
  description = "Enable session affinity"
  type        = bool
}

variable "session_affinity_ttl" {
  description = "Session affinity TTL"
  type        = string
}

variable "enable_circuit_breaker" {
  description = "Enable circuit breaker"
  type        = bool
}

variable "circuit_breaker_threshold" {
  description = "Circuit breaker threshold"
  type        = number
}

variable "circuit_breaker_timeout" {
  description = "Circuit breaker timeout"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
