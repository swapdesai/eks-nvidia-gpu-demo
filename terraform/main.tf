provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

################################################################################
# Common data/locals
################################################################################

# Only Availability Zones (no Local Zones)
data "aws_availability_zones" "available" {
  # Do not include local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  # Number of AZs we wish to create
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = merge(var.tags, {
  })
}
