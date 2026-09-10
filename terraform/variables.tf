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
