# =============================================================================
# IAM Module — Creates Cluster Role, Node Role, Pod Identity Roles, ArgoCD Role
# =============================================================================
module "iam" {
  source = "./modules/iam"

  cluster_name                 = var.cluster_name
  tags                         = var.tags
  pod_identity_roles           = var.pod_identity_roles
  argocd_capability_config     = var.argocd_capability_config
  aws_addons_with_pod_identity = var.aws_addons_with_pod_identity
}

# =============================================================================
# Network Data — Derive VPC ID from subnet IDs (avoids manual VPC ID input)
# =============================================================================
data "aws_subnet" "first" {
  id = var.subnet_ids[0]
}

# =============================================================================
# EKS Control Plane — Core cluster with bootstrap addons
# =============================================================================
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # Networking
  vpc_id     = data.aws_subnet.first.vpc_id
  subnet_ids = var.subnet_ids

  endpoint_private_access      = var.endpoint_private_access
  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  service_ipv4_cidr            = var.service_ipv4_cidr

  enabled_log_types   = var.log_types
  deletion_protection = var.deletion_protection

  upgrade_policy = {
    support_type = var.cluster_upgrade_policy_support_type
  }

  # IAM — Use pre-created role from module.iam to avoid circular dependencies
  create_iam_role = false
  iam_role_arn    = module.iam.cluster_role_arn

  # Encryption
  encryption_config = {}

  # VPN Access (optional)
  security_group_additional_rules = length(var.vpn_cidrs) > 0 ? {
    allow-vpn = {
      cidr_blocks = var.vpn_cidrs
      description = "Allow all traffic from VPN"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }
  } : {}

  # Access — API-based auth with cluster creator as admin
  authentication_mode                     = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true
  access_entries                          = var.access_entries

  # Bootstrap Addons — Installed BEFORE node groups (critical for networking)
  addons = {
    "kube-proxy" = {
      version = "v1.34.0-eksbuild.2"
    }
    "vpc-cni" = {
      version = "v1.20.4-eksbuild.2"
    }
    "eks-pod-identity-agent" = {
      version = "v1.3.10-eksbuild.2"
    }
  }

  # Tag node security group for Karpenter discovery
  node_security_group_tags = merge(var.tags, {
    "karpenter.sh/discovery" = var.cluster_name
  })

  tags = var.tags
}

# =============================================================================
# Managed Node Groups — Worker nodes (created AFTER bootstrap addons)
# =============================================================================
module "eks_managed_node_group" {
  source   = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version  = "21.15.1"
  for_each = var.node_groups

  name               = each.key
  cluster_name       = module.eks.cluster_name
  kubernetes_version = module.eks.cluster_version
  subnet_ids         = length(try(each.value.subnets, [])) > 0 ? each.value.subnets : var.subnet_ids

  vpc_security_group_ids = [module.eks.node_security_group_id]
  cluster_service_cidr   = module.eks.cluster_service_cidr

  # Scaling
  min_size     = each.value.scaling_config.min_size
  max_size     = each.value.scaling_config.max_size
  desired_size = each.value.scaling_config.desired_size

  # Instance
  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size

  # Labels and Taints
  labels = each.value.labels
  taints = each.value.taints

  # IAM — Use existing node role from IAM module
  create_iam_role = false
  iam_role_arn    = module.iam.node_role_arn

  tags = var.tags

  # Ensure node groups are created AFTER critical addons are installed
  depends_on = [module.iam, module.eks]
}

# =============================================================================
# CoreDNS — Installed AFTER node groups (pods need nodes to schedule)
# =============================================================================
resource "aws_eks_addon" "coredns" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "coredns"
  addon_version = "v1.12.3-eksbuild.1"

  # If Karpenter is enabled, add tolerations so CoreDNS can run on controller nodes
  configuration_values = var.karpenter_enabled ? jsonencode({
    tolerations = [
      {
        key    = "karpenter.sh/controller"
        value  = "true"
        effect = "NoSchedule"
      }
    ]
  }) : null

  tags = var.tags

  depends_on = [module.eks_managed_node_group]
}

# =============================================================================
# Cluster Auth Token — For Helm provider and post-cluster operations
# =============================================================================
data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

# =============================================================================
# Karpenter Subnet Tags — Required for Karpenter node discovery
# =============================================================================
resource "aws_ec2_tag" "subnets" {
  for_each    = var.karpenter_enabled ? toset(var.subnet_ids) : toset([])
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = module.eks.cluster_name
}

# =============================================================================
# ArgoCD Capability — Conditionally deploys ArgoCD onto the cluster
# =============================================================================
module "argocd_capability" {
  count   = var.argocd_capability_config.enabled ? 1 : 0
  source  = "terraform-aws-modules/eks/aws//modules/capability"
  version = "21.15.1"

  name         = var.argocd_capability.name
  cluster_name = module.eks.cluster_name
  type         = "ARGOCD"

  configuration = {
    argo_cd = {
      aws_idc = {
        idc_instance_arn = var.argocd_capability.idc_instance_arn
        idc_region       = var.argocd_capability.idc_region
      }
      namespace = var.argocd_capability.namespace
      rbac_role_mapping = [
        for k, v in var.argocd_capability.rbac_role_mappings : {
          role = v.role
          identity = [{
            id   = v.identity.id
            type = v.identity.type
          }]
        }
      ]
    }
  }

  create_iam_role = false
  iam_role_arn    = module.iam.argocd_role_arn

  delete_propagation_policy = var.argocd_capability.delete_propagation_policy
  tags                      = var.tags

  depends_on = [module.iam, module.eks]
}

# =============================================================================
# ArgoCD Access Policy — Grants ArgoCD role ClusterAdmin permissions
# =============================================================================
resource "aws_eks_access_policy_association" "this" {
  count         = var.argocd_capability_config.enabled ? 1 : 0
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.argocd_capability_config.principal_arn

  access_scope {
    type = "cluster"
  }

  # IMPORTANT: Wait for ArgoCD capability to settle before attaching policy
  # Without this, race condition can cause plan failures
  depends_on = [module.argocd_capability]
}

# =============================================================================
# Standalone Add-ons — Installed after nodes (no IAM requirements)
# =============================================================================
resource "aws_eks_addon" "this" {
  for_each = var.eks_addons

  cluster_name  = module.eks.cluster_name
  addon_name    = each.key
  addon_version = each.value.version

  tags = var.tags

  depends_on = [module.eks]
}

# =============================================================================
# Pod Identity Associations — Links IAM roles to K8s service accounts
# =============================================================================
resource "aws_eks_pod_identity_association" "this" {
  for_each = module.iam.pod_identity_roles

  cluster_name    = module.eks.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = each.value.role_arn

  tags = var.tags

  depends_on = [module.iam, module.eks]
}

# =============================================================================
# Add-ons with Pod Identity — Installs addon AND associates IAM role
# =============================================================================
resource "aws_eks_addon" "with_pod_identity" {
  for_each = var.aws_addons_with_pod_identity

  cluster_name  = module.eks.cluster_name
  addon_name    = each.key
  addon_version = each.value.version
  pod_identity_association {
    service_account = each.value.service_account
    role_arn        = module.iam.add_on_pod_identity_roles[each.key].role_arn
  }
  tags = var.tags

  depends_on = [module.eks]
}

# =============================================================================
# Karpenter Module — AWS infrastructure for node autoscaling
# =============================================================================
module "karpenter" {
  count        = var.karpenter_enabled ? 1 : 0
  source       = "terraform-aws-modules/eks/aws//modules/karpenter"
  version      = "21.15.1"
  cluster_name = module.eks.cluster_name

  # Reuse existing node role — no need for a separate Karpenter node role
  create_node_iam_role = false
  node_iam_role_arn    = module.iam.node_role_arn

  # Node group role already has an access entry
  create_access_entry = false
  namespace           = "karpenter"
  tags                = var.tags

  depends_on = [module.iam, module.eks]
}
