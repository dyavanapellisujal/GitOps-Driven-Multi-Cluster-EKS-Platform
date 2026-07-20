# Standalone add-ons (installed after node groups, no IAM needed)
eks_addons = {
  "eks-node-monitoring-agent" = {
    version = "v1.5.0-eksbuild.1"
  }
  "metrics-server" = {
    version = "v0.8.0-eksbuild.6"
  }
}

# Add-ons that require AWS IAM permissions via Pod Identity
aws_addons_with_pod_identity = {
  "aws-ebs-csi-driver" = {
    policy_arn      = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    namespace       = "kube-system"
    service_account = "ebs-csi-controller-sa"
    version         = "v1.55.0-eksbuild.1"
  }
  "aws-efs-csi-driver" = {
    policy_arn      = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
    namespace       = "kube-system"
    service_account = "efs-csi-controller-sa"
    version         = "v2.3.0-eksbuild.1"
  }
}
