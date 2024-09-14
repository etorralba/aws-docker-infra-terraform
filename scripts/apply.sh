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

terraform apply \
    -input=false \
    -auto-approve \
    -lock=true \
    "${PLAN_FILE}" | sed -e 's/^/    /g'