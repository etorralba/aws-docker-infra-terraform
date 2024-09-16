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

# if network layer, use the default workspace
if [ "$LAYER" == "network" ]; then
  ENVIRONMENT="default"
fi

terraform workspace select "${ENVIRONMENT}" || terraform workspace new "${ENVIRONMENT}" | sed -e 's/^/    /g'


VAR_FILE="./terraform.tfvars"

terraform destroy \
    -var-file="${VAR_FILE}" \
	-input=false \
	-auto-approve \
    -var "environment=${ENVIRONMENT_VARIABLE}" \
    -lock=true | sed -e 's/^/    /g'
