locals {
  vpc_id = "vpc-${var.project_name}-${var.environment}-${var.region}"

  private_subnet_ids = [
    for idx, az in var.azs : "subnet-${var.project_name}-${var.environment}-${var.region}-${idx + 1}-private"
  ]

  public_subnet_ids = [
    for idx, az in var.azs : "subnet-${var.project_name}-${var.environment}-${var.region}-${idx + 1}-public"
  ]
}
