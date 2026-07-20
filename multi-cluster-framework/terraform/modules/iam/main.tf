# =============================================================================
# Cluster IAM Role — Required for EKS control plane
# =============================================================================
resource "aws_iam_role" "cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster_role.name
}

# =============================================================================
# Node IAM Role — Required for EC2 worker nodes to join the cluster
# =============================================================================
resource "aws_iam_role" "node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

# =============================================================================
# Pod Identity Roles — Per-service IAM roles using EKS Pod Identity
# =============================================================================
resource "aws_iam_role" "pod_identity_role" {
  for_each = var.pod_identity_roles

  name = "${var.cluster_name}-${each.key}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEksAuthToAssumeRoleForPodIdentity"
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "pod_identity_policy" {
  for_each = var.pod_identity_roles

  name        = "${var.cluster_name}-${each.key}-policy"
  description = "Policy for ${each.key}"
  policy      = file("${path.module}/pod_policies/${each.value.policy_file}")
}

resource "aws_iam_role_policy_attachment" "pod_identity_attachment" {
  for_each = var.pod_identity_roles

  policy_arn = aws_iam_policy.pod_identity_policy[each.key].arn
  role       = aws_iam_role.pod_identity_role[each.key].name
}

# =============================================================================
# Add-on Pod Identity Roles — For AWS-managed addons (EBS CSI, EFS CSI, etc.)
# =============================================================================
resource "aws_iam_role" "add_on_pod_identity_role" {
  for_each = var.aws_addons_with_pod_identity

  name = "${var.cluster_name}-${each.key}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEksAuthToAssumeRoleForPodIdentity"
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "add_on_pod_identity_attachment" {
  for_each = var.aws_addons_with_pod_identity

  policy_arn = each.value.policy_arn
  role       = aws_iam_role.add_on_pod_identity_role[each.key].name
}

# =============================================================================
# ArgoCD IAM Role — For EKS ArgoCD Capability (conditionally created)
# =============================================================================
resource "aws_iam_role" "argocd_role" {
  count = var.argocd_capability_config.enabled ? 1 : 0
  name  = "${var.cluster_name}-argocd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Effect = "Allow"
        Principal = {
          Service = "capabilities.eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "argocd_policy" {
  count       = var.argocd_capability_config.enabled ? 1 : 0
  name        = "${var.cluster_name}-argocd-policy"
  description = "Policy for ArgoCD capability"
  policy      = file("${path.module}/pod_policies/common/argocd_policy.json")
}

resource "aws_iam_role_policy_attachment" "argocd_policy_attachment" {
  count      = var.argocd_capability_config.enabled ? 1 : 0
  policy_arn = aws_iam_policy.argocd_policy[0].arn
  role       = aws_iam_role.argocd_role[0].name
}
