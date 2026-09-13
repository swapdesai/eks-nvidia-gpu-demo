variable "name" {
  description = "Name of the VPC and EKS Cluster"
  default     = "automode-cluster"
  type        = string
}

variable "region" {
  description = "region"
  default     = "ap-southeast-2"
  type        = string
}

variable "eks_cluster_version" {
  description = "EKS Cluster version"
  default     = "1.36"
  type        = string
}

# VPC with 65536 IPs (10.0.0.0/16) for 3 AZs
variable "vpc_cidr" {
  description = "VPC CIDR. This should be a valid private (RFC 1918) CIDR range"
  default     = "10.0.0.0/16"
  type        = string
}

variable "endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = []
}

variable "my_cidr" {
  description = "CIDR allowed to reach the Grafana ALB Ingress. Defaults to 0.0.0.0/0 (open to the world); override with your own IP/32 to restrict access."
  type        = string
  default     = ""
}
variable "enable_amazon_prometheus" {
  description = "Provision an Amazon Managed Prometheus workspace and IAM for the scraper."
  type        = bool
  default     = true
}

variable "kube_prometheus_stack_version" {
  description = "kube-prometheus-stack chart version."
  type        = string
  default     = "90.0.0"
}

variable "enable_dcgm_exporter" {
  description = "Install the NVIDIA DCGM exporter on GPU nodes for Prometheus scraping."
  type        = bool
  default     = true
}
variable "dcgm_exporter_version" {
  description = "NVIDIA dcgm-exporter chart version."
  type        = string
  default     = "4.8.3"
}
variable "tags" {
  description = "Tags applied to every taggable AWS resource (provider default_tags, EKS primary SG, NodeClass-launched EC2/EBS/ENI, EBS volumes via StorageClass, ALB via IngressClassParams). Override to integrate with your tagging policy."
  type        = map(string)
  default = {
    "auto-delete" = "never"
  }
}

variable "nodepools" {
  description = <<-EOT
    GPU NodePool strategies to enable, keyed by folder name under nodepools/. Defaults to
    {} (no GPU NodePools). Set `reservation` on a strategy to have Terraform create a
    tagged On-Demand Capacity Reservation (ODCR) for it; the NodeClass selects it by the
    nodepool=<key> tag. An ODCR bills immediately until destroyed.

    spot-ondemand and reserved-spot-ondemand both manage the gpu-inf pool and are
    mutually exclusive. To add a strategy: create nodepools/<name>/ and add <name> to the validation list.
  EOT
  type = map(object({
    reservation = optional(object({
      instance_type  = optional(string, "g6e.4xlarge")
      instance_count = optional(number, 1)
      az             = optional(string, "") # defaults to the first cluster AZ
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k in keys(var.nodepools) : contains([
        "spot-ondemand",
        "reserved-spot-ondemand",
      ], k)
    ])
    error_message = "Each key must be an existing strategy folder under nodepools/."
  }

  validation {
    condition = length(setintersection(keys(var.nodepools), [
      "spot-ondemand",
      "reserved-spot-ondemand",
    ])) <= 1
    error_message = "Enable at most one GPU inference strategy (spot-ondemand, reserved-spot-ondemand); each is a complete solution for the gpu-inf workload."
  }

  validation {
    condition = alltrue([
      for k, v in var.nodepools :
      contains(["reserved-spot-ondemand"], k) ? v.reservation != null : true
    ])
    error_message = "reserved-spot-ondemand requires a `reservation` (its reserved nodes run on an ODCR)."
  }
}
