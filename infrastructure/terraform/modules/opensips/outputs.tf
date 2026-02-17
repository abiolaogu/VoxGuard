output "sip_endpoint" {
  description = "OpenSIPS SIP endpoint"
  value       = local.sip_endpoint
}

output "management_endpoint" {
  description = "OpenSIPS management endpoint"
  value       = local.management_endpoint
}

output "service_endpoints" {
  description = "OpenSIPS service endpoints"
  value       = local.service_endpoints
}

output "region" {
  description = "Region for this deployment"
  value       = var.region
}

output "is_primary" {
  description = "Whether this deployment is in primary region"
  value       = var.is_primary
}
