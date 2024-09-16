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

export AWS_PAGER=""

source ./scripts/init.sh $LAYER $ORGANIZATION

ENVIRONMENT_VARIABLE=$ENVIRONMENT

if [ "$LAYER" == "network" ]; then
  ENVIRONMENT="default"

elif [ "$LAYER" == "compute" ]; then
  REPOSITORIES=$(aws ecr describe-repositories --query "repositories[?contains(repositoryName, '$ENVIRONMENT')].repositoryName" --output text)

  if [ -n "$REPOSITORIES" ]; then
    for REPO in $REPOSITORIES; do
      echo "Looking for images in repository: $REPO for environment: $ENVIRONMENT"

      IMAGE_IDS=$(aws ecr list-images --repository-name "$REPO" --query "imageIds[*]" --output json)

      if [ "$IMAGE_IDS" != "[]" ]; then
        echo "Deleting images from repository: $REPO"

        aws ecr batch-delete-image --repository-name "$REPO" --image-ids "$IMAGE_IDS"

        echo "Deleted images from repository: $REPO"
      else
        echo "No images to delete in repository: $REPO"
      fi
    done
  else
    echo "No repositories found for environment: $ENVIRONMENT. Skipping image deletion."
  fi
fi

terraform workspace select "${ENVIRONMENT}" || terraform workspace new "${ENVIRONMENT}" | sed -e 's/^/    /g'

VAR_FILE="./terraform.tfvars"

DESTROY_COMMAND="terraform destroy -input=false -auto-approve -var \"environment=${ENVIRONMENT_VARIABLE}\" -lock=true"

if [ -f "$VAR_FILE" ]; then
  DESTROY_COMMAND="$DESTROY_COMMAND -var-file=\"$VAR_FILE\""
fi

DESTROY_COMMAND="$DESTROY_COMMAND $@"

eval $DESTROY_COMMAND | sed -e 's/^/    /g'
