#!/bin/bash

set -e
set -o pipefail

# Arguments:
# $1: Layer
# $2: Organization
# $3: Environment

LAYER=$1
ORGANIZATION=$2
ENVIRONMENT=$3

source ./scripts/init.sh $LAYER $ORGANIZATION

ENVIRONMENT_VARIABLE=$ENVIRONMENT

if [ "$LAYER" == "network" ]; then
  ENVIRONMENT="default"
fi

terraform workspace select "${ENVIRONMENT}" || terraform workspace new "${ENVIRONMENT}"

PLAN_FILE="./terraform.${ORGANIZATION}_${LAYER}.tfplan"
VAR_FILE="./terraform.tfvars"

terraform plan \
	-input=false \
	-out="${PLAN_FILE}" \
	-lock=true \
	-var "environment=${ENVIRONMENT_VARIABLE}" \
	-var-file="${VAR_FILE}" | sed -e 's/^/    /g'

terraform show -json "${PLAN_FILE}" >"${PLAN_FILE}.json"