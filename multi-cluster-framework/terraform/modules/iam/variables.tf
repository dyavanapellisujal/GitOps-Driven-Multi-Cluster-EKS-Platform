variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "pod_identity_roles" {
  description = "Map of pod identity role configurations"
  type = map(object({
    policy_file     = string
    namespace       = string
    service_account = string
  }))
  default = {}
}

variable "argocd_capability_config" {
  description = "ArgoCD capability toggle"
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
  description = "Map of add-on pod identity role configurations"
  type = map(object({
    policy_arn      = string
    namespace       = string
    service_account = string
    version         = string
  }))
  default = {}
}
