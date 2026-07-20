terraform {
  backend "s3" {
    # Backend configuration is loaded from backends/<env>.hcl
    # Run: terraform init -backend-config=backends/<env>.hcl -reconfigure
  }
}
