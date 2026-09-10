locals {
  name = var.eks_cluster_version

  # Auto Mode bundles vpc-cni, kube-proxy, coredns, ebs-csi, pod-identity-agent, eks-node-monitoring-agent.
  # metrics-server isn't bundled and is installed as a standalone addon.
  standalone_addons = {
    metrics-server = {
      preserve                    = false
      resolve_conflicts_on_update = "PRESERVE"
    }
  }
}

###############################################################################
# EKS Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.25"

  name               = var.name
  kubernetes_version = var.eks_cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  # control_plane_subnet_ids = module.vpc.private_subnets

  # Public Mode Only Network Settings
  endpoint_public_access  = true
  endpoint_private_access = true

  # Restrict public access to the cluster API server
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  encryption_config = {
    resources = ["secrets"]
  }

  # Enable Auto Mode built-in NodePools.
  # `system` (CriticalAddonsOnly tainted, both amd64 and arm64) for cluster-critical workloads.
  # `general-purpose` (amd64, untainted) for general workloads.
  compute_config = {
    enabled    = true
    node_pools = ["system", "general-purpose"]
  }

  node_iam_role_additional_policies = {
    AmazonElasticContainerRegistryPublicReadOnly = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly"
  }

  # Module handles the IAM policy for custom tags on Auto Mode resources (Layer 3 enabler)
  enable_auto_mode_custom_tags = true
}

#---------------------------------------------------------------
# Pod Identity trust
#---------------------------------------------------------------

data "aws_iam_policy_document" "pod_identity_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

#---------------------------------------------------------------
# Standalone addons
#---------------------------------------------------------------

resource "aws_eks_addon" "standalone" {
  for_each = local.standalone_addons

  cluster_name                = module.eks.cluster_name
  addon_name                  = each.key
  preserve                    = each.value.preserve
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update

  depends_on = [module.eks]
}
