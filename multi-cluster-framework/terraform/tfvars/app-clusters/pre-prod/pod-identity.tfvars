# Pod Identity roles — per-service least-privilege AWS permissions
pod_identity_roles = {
  "alb-controller" = {
    policy_file     = "common/alb_controller_policy.json"
    namespace       = "kube-system"
    service_account = "aws-load-balancer-controller"
  }

  "service-a" = {
    policy_file     = "pre-prod/api_server_policy.json"
    namespace       = "pre-prod"
    service_account = "service-a"
  }

  # Add more as needed:
  # "my-worker-service" = {
  #   policy_file     = "pre-prod/worker_policy.json"
  #   namespace       = "pre-prod"
  #   service_account = "my-worker-service"
  # }
}
