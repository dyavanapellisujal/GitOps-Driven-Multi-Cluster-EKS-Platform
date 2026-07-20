cluster_name       = "my-app-pre-prod-cluster"
kubernetes_version = "1.34"

# API Server Endpoint Access
endpoint_private_access      = true
endpoint_public_access       = true
endpoint_public_access_cidrs = ["203.0.113.0/24"] # Your office/VPN CIDR

service_ipv4_cidr                   = "10.101.0.0/16"
deletion_protection                 = true
cluster_upgrade_policy_support_type = "STANDARD"

# Access Entries — Who can access this cluster
access_entries = {
  admin = {
    principal_arn     = "arn:aws:iam::123456789012:role/aws-reserved/sso.amazonaws.com/your-region/AWSReservedSSO_AdministratorAccess_abc123"
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

  ci_cd = {
    principal_arn     = "arn:aws:iam::123456789012:user/CI-CD-User"
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
    principal_arn     = "arn:aws:iam::123456789012:role/aws-reserved/sso.amazonaws.com/your-region/AWSReservedSSO_Developer_xyz789"
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

  #if argo cd runs in different cluster then add that role here
}

# Karpenter
karpenter_enabled = true

# VPN Access
vpn_cidrs = ["10.0.0.50/32"]

# ArgoCD Capability — Enabled in pre-prod this will enable argocd capability and creates this role in this cluster
# This can later be referenced in other clusters to give them argocd capability
# if false then you will have to mention the argocd role of argo capability in access_entries
argocd_capability_config = {
  enabled       = true
  principal_arn = "arn:aws:iam::123456789012:role/my-app-pre-prod-cluster-argocd-role"
}

argocd_capability = {
  name                      = "argocd"
  delete_propagation_policy = "RETAIN"
  idc_instance_arn          = "arn:aws:sso:::instance/ssoins-abc123def456"
  idc_region                = "your-region"
  namespace                 = "argocd"
  rbac_role_mappings = {
    "ADMINS" = {
      role = "ADMIN"
      identity = {
        type = "SSO_GROUP"
        id   = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
      }
    }
  }
}
