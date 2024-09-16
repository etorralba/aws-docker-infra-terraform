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

OUTPUT_DIR="./terraform.${ORGANIZATION}_${LAYER}_output.json"

terraform output -json > "${OUTPUT_DIR}"

echo "Outputs for layer ${LAYER} written to ${OUTPUT_DIR}"