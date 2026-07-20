aws_region = "your-pre-prod-region"

subnet_ids = ["subnet-0abc1234def567890", "subnet-0def4567abc890123"]

tags = {
  Environment = "pre-prod"
  Project     = "eks-platform"
  ManagedBy   = "Terraform"
}
