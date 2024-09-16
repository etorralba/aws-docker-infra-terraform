#!/bin/bash

set -e
set -o pipefail

# Arguments:
# $1: Layer
# $2: Organization
# $3: Environment
# $@: Additional parameters (e.g., -var options)

LAYER=$1
ORGANIZATION=$2
ENVIRONMENT=$3
shift 3

source ./scripts/init.sh $LAYER $ORGANIZATION

ENVIRONMENT_VARIABLE=$ENVIRONMENT

if [ "$LAYER" == "network" ]; then
	ENVIRONMENT="default"
fi

terraform workspace select "${ENVIRONMENT}" || terraform workspace new "${ENVIRONMENT}"

PLAN_FILE="./terraform.${ORGANIZATION}_${LAYER}.tfplan"
VAR_FILE="./terraform.tfvars"

PLAN_COMMAND="terraform plan -input=false -out=\"${PLAN_FILE}\" -lock=true -var \"environment=${ENVIRONMENT_VARIABLE}\""

if [ -f "$VAR_FILE" ]; then
	PLAN_COMMAND="$PLAN_COMMAND -var-file=\"$VAR_FILE\""
fi

PLAN_COMMAND="$PLAN_COMMAND $@"

eval $PLAN_COMMAND

terraform show -json "${PLAN_FILE}" >"${PLAN_FILE}.json"
