output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

output "argo_cd_api_endpoint" {
  description = "API Endpoint for ArgoCD capability"
  value       = try(module.argocd_capability[0].server_url, null)
}

output "interruption_queue" {
  description = "Karpenter SQS interruption queue name"
  value       = try(module.karpenter[0].queue_name, null)
}
