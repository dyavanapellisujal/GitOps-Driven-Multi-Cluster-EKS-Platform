node_groups = {
  # Default worker node group
  "region-2-worker-group" = {
    instance_types = ["t3a.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
    scaling_config = {
      max_size     = 4
      min_size     = 2
      desired_size = 2
    }
  }

  # Dedicated Karpenter controller node group
  "region-2-karpenter-group" = {
    instance_types = ["t3a.medium"]
    capacity_type  = "ON_DEMAND"    # Always ON_DEMAND — Karpenter must always be running
    disk_size      = 50
    scaling_config = {
      max_size     = 2
      min_size     = 1
      desired_size = 1
    }
    labels = {
      "karpenter.sh/controller" = "true"    # nodeSelector target for Karpenter pods
    }
    taints = {
      karpenter = {
        key    = "karpenter.sh/controller"
        value  = "true"
        effect = "NO_SCHEDULE"              # Only Karpenter pods run on these nodes
      }
    }
  }
}
