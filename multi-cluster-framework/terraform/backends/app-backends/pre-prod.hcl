bucket         = "my-terraform-state-bucket"
key            = "eks/pre-prod/terraform.tfstate"
region         = "your-pre-prod-region"
dynamodb_table = "terraform-state-lock"
encrypt        = true
