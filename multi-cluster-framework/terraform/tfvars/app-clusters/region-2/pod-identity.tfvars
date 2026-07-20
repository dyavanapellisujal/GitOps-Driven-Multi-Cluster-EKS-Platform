# Pod Identity roles — per-service least-privilege AWS permissions.
# Note the policy_file paths point at region-2/* so this region's roles can only
# reach this region's resources — least privilege scoped by geography.
pod_identity_roles = {
  "alb-controller" = {
    policy_file     = "common/alb_controller_policy.json"
    namespace       = "kube-system"
    service_account = "aws-load-balancer-controller"
  }

  "my-api-server" = {
    policy_file     = "region-2/api_server_policy.json"
    namespace       = "region-2"
    service_account = "my-api-server"
  }
}
