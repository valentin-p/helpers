#!/bin/bash

NAMESPACE="platform"

echo "Listing all deployments in the $NAMESPACE namespace:"
kubectl get deployments -n $NAMESPACE

# Get the names of all deployments
deployments=$(kubectl get deployments -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')

# Split the deployments string on whitespace
IFS=' ' read -r -a deployment_array <<< "$deployments"

for deployment in "${deployment_array[@]}"; do
  echo "Describing deployment: $deployment"
  kubectl describe deployment "$deployment" -n $NAMESPACE
done
