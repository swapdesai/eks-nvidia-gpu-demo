data "aws_availability_zones" "available" {
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

locals {
  vpc_cidr = var.vpc_cidr

  # AZs that don't support the EKS control plane. AZ IDs are stable across accounts — AZ names are
  # randomized per-account, so filtering by name silently misses the constraint.
  # See https://docs.aws.amazon.com/eks/latest/userguide/network-reqs.html#network-requirements-subnets.
  excluded_zone_ids = ["use1-az3", "usw1-az2", "cac1-az3"]

  available_azs = [
    for i, name in data.aws_availability_zones.available.names :
    name if !contains(local.excluded_zone_ids, data.aws_availability_zones.available.zone_ids[i])
  ]

  # Use every usable AZ the region has. Capped at 8 as a safety limit on the CIDR math below (no
  # AWS region currently has more than 6 AZs), not a user-facing setting.
  az_count = min(length(local.available_azs), 8)
  azs      = slice(local.available_azs, 0, local.az_count)

  # /20 subnets computed from the VPC /16 CIDR — 16 possible /20s total, public taking indexes
  # [0, az_count) and private taking [az_count, 2*az_count).
  public_subnets_cidrs  = [for i in range(local.az_count) : cidrsubnet(local.vpc_cidr, 4, i)]
  private_subnets_cidrs = [for i in range(local.az_count) : cidrsubnet(local.vpc_cidr, 4, local.az_count + i)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7"

  name = var.name
  cidr = local.vpc_cidr
  azs  = local.azs

  private_subnets = local.public_subnets_cidrs
  public_subnets  = local.private_subnets_cidrs

  enable_nat_gateway = false
  # single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = var.name
  }
}
