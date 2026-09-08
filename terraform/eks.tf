###############################################################################
# EKS Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.25"

  name               = var.name
  kubernetes_version = var.eks_cluster_version

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Public Mode Only Network Settings
  endpoint_public_access  = true
  endpoint_private_access = false

  # Restrict public access to the cluster API server
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  # Module handles the IAM policy for custom tags on Auto Mode resources (Layer 3 enabler)
  enable_auto_mode_custom_tags = true
}
