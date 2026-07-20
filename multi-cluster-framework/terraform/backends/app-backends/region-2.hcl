bucket         = "my-terraform-state-bucket"
key            = "eks/region-2/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true
