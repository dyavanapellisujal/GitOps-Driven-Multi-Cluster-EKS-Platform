cluster_name       = "my-app-region-2-cluster"
kubernetes_version = "1.34"

# API Server Endpoint Access
endpoint_private_access      = true
endpoint_public_access       = true
endpoint_public_access_cidrs = ["203.0.113.0/24"] # Your office/VPN CIDR

service_ipv4_cidr                   = "10.102.0.0/16"
deletion_protection                 = true
cluster_upgrade_policy_support_type = "STANDARD"

# Access Entries — Who can access this cluster
#
# region-2 is a SPOKE cluster: it does NOT host ArgoCD. Instead it trusts the
# ArgoCD role created on the hub cluster (pre-prod) so that the central ArgoCD
# can reconcile workloads here. This is the cross-cluster trust the blog describes:
# Terraform grants the trust, the GitOps repo declares the intent.
access_entries = {
  admin = {
    principal_arn     = "arn:aws:iam::123456789012:role/aws-reserved/sso.amazonaws.com/eu-west-1/AWSReservedSSO_AdministratorAccess_abc123"
    kubernetes_groups = []
    policy_associations = {
      cluster_admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
          type = "cluster"
        }
      }
    }
  }

  developers = {
    principal_arn     = "arn:aws:iam::123456789012:role/aws-reserved/sso.amazonaws.com/eu-west-1/AWSReservedSSO_Developer_xyz789"
    kubernetes_groups = []
    policy_associations = {
      view_only = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
        access_scope = {
          type = "cluster"
        }
      }
    }
  }

  # Cross-cluster: trust the hub's ArgoCD role so central ArgoCD can manage this cluster.
  # The ARN below is the argocd_capability_config.principal_arn from the hub (pre-prod).
  argocd_cross_cluster = {
    principal_arn     = "arn:aws:iam::123456789012:role/my-app-pre-prod-cluster-argocd-role"
    kubernetes_groups = []
    policy_associations = {
      cluster_admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
          type = "cluster"
        }
      }
    }
  }
}

# Karpenter
karpenter_enabled = true

# VPN Access
vpn_cidrs = ["10.0.0.50/32"]

# ArgoCD Capability — DISABLED on region-2.
# This cluster is a spoke; ArgoCD lives on the hub (pre-prod) and reaches in via
# the argocd_cross_cluster access entry above. No capability role is created here.
argocd_capability_config = {
  enabled       = false
  principal_arn = ""
}
