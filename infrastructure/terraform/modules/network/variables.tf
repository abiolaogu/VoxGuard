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

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "Availability zones in this region"
  type        = list(string)
}

variable "enable_vpn_mesh" {
  description = "Whether to enable VPN mesh"
  type        = bool
  default     = false
}

variable "peer_regions" {
  description = "Peer regions for mesh networking"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
