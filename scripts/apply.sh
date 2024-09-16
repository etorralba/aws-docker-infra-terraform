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

if [ "$LAYER" == "network" ]; then
  ENVIRONMENT="default"
fi

terraform workspace select "${ENVIRONMENT}" || terraform workspace new "${ENVIRONMENT}"

PLAN_FILE="./terraform.${ORGANIZATION}_${LAYER}.tfplan"

terraform apply \
    -input=false \
    -auto-approve \
    -lock=true \
    "${PLAN_FILE}" | sed -e 's/^/    /g'