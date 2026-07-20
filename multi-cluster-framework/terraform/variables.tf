variable "aws_region" {
  description = "AWS Region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "eks-platform"
    ManagedBy   = "Terraform"
  }
}

variable "subnet_ids" {
  description = "List of existing subnet IDs for the EKS cluster and node groups"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "endpoint_public_access_cidrs" {
  description = "List of CIDR blocks to allow public access to the cluster endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_upgrade_policy_support_type" {
  description = "Support type to use for the cluster (STANDARD, EXTENDED)"
  type        = string
  default     = "STANDARD"
}

variable "service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "If true, enables deletion protection on the EKS cluster"
  type        = bool
  default     = false
}

variable "endpoint_private_access" {
  description = "Enable private access to the cluster endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access to the cluster endpoint"
  type        = bool
  default     = true
}

variable "eks_addons" {
  description = "Map of addons to be installed as standalone resources (after node groups)"
  type = map(object({
    configuration_values = optional(string)
    version              = string
  }))
  default = {}
}

variable "access_entries" {
  description = "Map of IAM principals to access entries and policy associations"
  type = map(object({
    principal_arn     = string
    kubernetes_groups = optional(list(string), [])
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        type       = string
        namespaces = optional(list(string))
      })
    })), {})
  }))
  default = {}
}

variable "pod_identity_roles" {
  description = "Map of pod identity role configurations. Key is the role identifier."
  type = map(object({
    policy_file     = string # Path relative to modules/iam/pod_policies/
    namespace       = string # K8s namespace for pod identity association
    service_account = string # K8s service account name
  }))
  default = {}
}

variable "node_groups" {
  description = "Map of node group configurations. Each key is the node group name."
  type = map(object({
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    instance_types = optional(list(string), ["t3.medium"])
    capacity_type  = optional(string, "ON_DEMAND")
    disk_size      = optional(number, 20)
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })
    labels = optional(map(string), {})
    taints = optional(map(object({
      key    = string
      value  = string
      effect = string
    })), {})
    subnets = optional(list(string), [])
  }))
  default = {}
}

variable "argocd_capability" {
  description = "ArgoCD capability configuration"
  type = object({
    name                      = string
    delete_propagation_policy = optional(string, "RETAIN")
    idc_instance_arn          = string
    idc_region                = optional(string, "your-region")
    namespace                 = optional(string, "argocd")
    rbac_role_mappings = optional(map(object({
      role = string
      identity = object({
        type = string
        id   = string
      })
    })), {})
  })
  default = null
}

variable "argocd_capability_config" {
  description = "ArgoCD capability toggle and principal ARN"
  type = object({
    enabled       = bool
    principal_arn = string
  })
  default = {
    enabled       = false
    principal_arn = ""
  }
}

variable "aws_addons_with_pod_identity" {
  description = "Map of add-on pod identity role configurations."
  type = map(object({
    policy_arn      = string
    namespace       = string
    service_account = string
    version         = string
  }))
  default = {}
}

variable "karpenter_enabled" {
  description = "Enable Karpenter for the EKS cluster"
  type        = bool
  default     = false
}

variable "vpn_cidrs" {
  description = "List of VPN CIDR blocks allowed to access the cluster nodes"
  type        = list(string)
  default     = []
}
