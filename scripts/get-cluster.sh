#!/usr/bin/env bash

set -e

INPUT=$(tee)

BIN_DIR=$(echo "${INPUT}" | sed -E 's/.*"bin_dir": ?"([^"]+)".*/\1/g')

eval "$(echo "$INPUT" | ${BIN_DIR}/jq -r '@sh "CLUSTER_NAME=\(.cluster_name) RESOURCE_GROUP_NAME=\(.resource_group_name) SUBSCRIPTION_ID=\(.subscription_id) TENANT_ID=\(.tenant_id) CLIENT_ID=\(.client_id)" CLIENT_SECRET=\(.client_secret)')"

API_VERSION="2019-04-30"

#CLIENT_ID=""
#CLIENT_SECRET=""
#TENANT_ID=""

TOKEN=$(curl -s -X POST -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&resource=https%3A%2F%2Fmanagement.azure.com%2F" "https://login.microsoftonline.com/${TENANT_ID}/oauth2/token" | ${BIN_DIR}/jq -r '.access_token')

URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.ContainerService/openShiftManagedClusters/${CLUSTER_NAME}?api-version=${API_VERSION}"

curl -s -X GET \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  "${URL}" | \
  ${BIN_DIR}/jq '{id: .id, location: .location, fqdn: .properties.fqdn, publicHostname: .properties.publicHostname, router_fqdn: .properties.routerProfiles[0].fqdn, publicSubdomain: .properties.routerProfiles[0].publicSubdomain}'
