#!/bin/bash

set -e
set -o pipefail

# Arguments:
# $1: Layer
# $2: Organization

LAYER=$1
ORGANIZATION=$2

source ./scripts/init.sh $LAYER $ORGANIZATION
VAR_FILE="./terraform.tfvars"

terraform destroy \
    -var-file="${VAR_FILE}" \
	-input=false \
	-auto-approve \
    -lock=true | sed -e 's/^/    /g'
