#!/bin/bash

set -e
set -o pipefail

# Arguments:
# $1: Layer
# $2: Organization

LAYER=$1
ORGANIZATION=$2

source ./scripts/init.sh $LAYER $ORGANIZATION

PLAN_FILE="./terraform.${ORGANIZATION}_${LAYER}.tfplan"
VAR_FILE="./terraform.tfvars"

terraform plan \
	-input=false \
	-out="${PLAN_FILE}" \
	-lock=true \
	-var-file="${VAR_FILE}" | sed -e 's/^/    /g'

terraform show -json "${PLAN_FILE}" >"${PLAN_FILE}.json"