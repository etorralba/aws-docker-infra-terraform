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

export AWS_PAGER=""

source ./scripts/init.sh $LAYER $ORGANIZATION

ENVIRONMENT_VARIABLE=$ENVIRONMENT

# if network layer, use the default workspace
if [ "$LAYER" == "network" ]; then
  ENVIRONMENT="default"

# if compute layer, delete all images from repositories
elif [ "$LAYER" == "compute" ]; then
  # Get all repositories that match the environment name
  REPOSITORIES=$(aws ecr describe-repositories --query "repositories[?contains(repositoryName, '$ENVIRONMENT')].repositoryName" --output text)

  if [ -n "$REPOSITORIES" ]; then
    for REPO in $REPOSITORIES; do
      echo "Looking for images in repository: $REPO for environment: $ENVIRONMENT"

      # Get image IDs for all images in the repository
      IMAGE_IDS=$(aws ecr list-images --repository-name "$REPO" --query "imageIds[*]" --output json)

      if [ "$IMAGE_IDS" != "[]" ]; then
        echo "Deleting images from repository: $REPO"

        # Batch delete the images
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

terraform destroy \
  -var-file="${VAR_FILE}" \
  -input=false \
  -auto-approve \
  -var "environment=${ENVIRONMENT_VARIABLE}" \
  -lock=true | sed -e 's/^/    /g'
