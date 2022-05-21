#!/usr/bin/env bash

set -e

SUBSCRIPTION_ID="$1"
RESOURCE_GROUP_NAME="$2"
CLUSTER_NAME="$3"

# Unable to perform the below as the service principal would require AAD access since ARO creates a new service principal
#echo "Logging in with service principal. client-id=${CLIENT_ID}, tenant-id=${TENANT_ID}"
#az login --service-principal -u "${CLIENT_ID}" -p "${CLIENT_SECRET}" -t "${TENANT_ID}"

echo "Setting subscription id: ${SUBSCRIPTION_ID}"
az account set --subscription "${SUBSCRIPTION_ID}"

az aro delete --name ${CLUSTER_NAME} --resource-group ${RESOURCE_GROUP_NAME} --yes