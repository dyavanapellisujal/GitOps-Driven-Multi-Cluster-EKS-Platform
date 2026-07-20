output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.cluster_role.arn
}

output "node_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.node_role.arn
}

output "pod_identity_roles" {
  description = "Map of pod identity role configurations with ARNs"
  value = {
    for k, v in var.pod_identity_roles : k => {
      role_arn        = aws_iam_role.pod_identity_role[k].arn
      namespace       = v.namespace
      service_account = v.service_account
    }
  }
}

output "argocd_role_arn" {
  description = "ARN of the ArgoCD IAM role"
  value       = try(aws_iam_role.argocd_role[0].arn, "")
}

output "add_on_pod_identity_roles" {
  description = "Map of add-on pod identity role configurations with ARNs"
  value = {
    for k, v in var.aws_addons_with_pod_identity : k => {
      role_arn        = aws_iam_role.add_on_pod_identity_role[k].arn
      namespace       = v.namespace
      service_account = v.service_account
    }
  }
}
