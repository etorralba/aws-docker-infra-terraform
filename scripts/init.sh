#!/bin/bash

set -e
set -o pipefail

# Arguments:
# $1: Layer
# $2: Organization

LAYER=$1
ORGANIZATION=$2

# Retrieve AWS account ID and region from environment variables
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID
AWS_REGION=$AWS_REGION
AWS_PROFILE=$AWS_PROFILE
TERRAFORM_DIR="terraform/${LAYER}"

cd $TERRAFORM_DIR

terraform init \
  -reconfigure \
  -input=false \
  -backend=true \
  -backend-config="bucket=${AWS_ACCOUNT_ID}-tf-state" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="key=terraform.${ORGANIZATION}_${LAYER}.tfstate" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=${AWS_ACCOUNT_ID}-tf-locks"

echo "Terraform initialized successfully"