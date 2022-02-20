#!/usr/bin/env bash

set -e

SUBSCRIPTION_ID="$1"
RESOURCE_GROUP_NAME="$2"
CLUSTER_NAME="$3"

API_VERSION="2019-04-30"

TOKEN=$(curl -X POST -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&resource=https%3A%2F%2Fmanagement.azure.com%2F" "https://login.microsoftonline.com/${TENANT_ID}/oauth2/token")

URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.ContainerService/openShiftManagedClusters/${CLUSTER_NAME}?api-version=${API_VERSION}"

curl -X DELETE \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  "${URL}"
