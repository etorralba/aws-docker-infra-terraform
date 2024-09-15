#!/bin/bash

set -e
set -o pipefail

BASE_DIR="terraform/"

for dir in $(find "$BASE_DIR" -type d); do
  echo "Running terraform fmt in $dir"
  terraform fmt "$dir"
done

echo "Terraform formatting completed."
