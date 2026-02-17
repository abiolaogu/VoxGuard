locals {
  sip_endpoint        = "sip.${var.region}.${var.environment}.voxguard.internal"
  management_endpoint = "https://opensips.${var.region}.${var.environment}.voxguard.internal/mi"

  service_endpoints = [
    local.sip_endpoint,
    local.management_endpoint,
  ]
}
