#!/bin/bash
# Terraform wrapper script for multi-environment app cluster deployments
# Usage: ./tf.sh <environment> <action>

set -e

ENV=$1
ACTION=$2

if [[ -z "$ENV" ]] || [[ -z "$ACTION" ]]; then
  echo "Usage: ./tf.sh <environment> <action>"
  echo "  Environments: pre-prod, region-1, region-2"
  echo "  Actions: init, plan, apply, destroy"
  echo ""
  echo "Examples:"
  echo "  ./tf.sh pre-prod plan"
  echo "  ./tf.sh region-1 apply"
  exit 1
fi

# Validate backend config exists
if [[ ! -f "backends/app-backends/${ENV}.hcl" ]]; then
  echo "Error: Backend config 'backends/app-backends/${ENV}.hcl' not found"
  exit 1
fi

# Validate tfvars directory exists
if [[ ! -d "tfvars/app-clusters/${ENV}" ]]; then
  echo "Error: tfvars directory 'tfvars/app-clusters/${ENV}' not found"
  exit 1
fi

# Auto-discover all tfvars files for this environment
VAR_FILES=""
for f in tfvars/app-clusters/${ENV}/*.tfvars; do
  VAR_FILES="$VAR_FILES -var-file=$f"
done

case $ACTION in
  init)
    echo "Initializing Terraform for environment: ${ENV}"
    terraform init -backend-config=backends/app-backends/${ENV}.hcl -reconfigure
    ;;
  plan)
    echo "Planning Terraform for environment: ${ENV}"
    terraform init -backend-config=backends/app-backends/${ENV}.hcl -reconfigure
    terraform plan $VAR_FILES
    ;;
  apply)
    echo "Applying Terraform for environment: ${ENV}"
    terraform init -backend-config=backends/app-backends/${ENV}.hcl -reconfigure
    terraform apply $VAR_FILES
    ;;
  destroy)
    echo "Destroying Terraform for environment: ${ENV}"
    terraform init -backend-config=backends/app-backends/${ENV}.hcl -reconfigure
    terraform destroy $VAR_FILES
    ;;
  *)
    echo "Unknown action: $ACTION"
    echo "Valid actions: init, plan, apply, destroy"
    exit 1
    ;;
esac
