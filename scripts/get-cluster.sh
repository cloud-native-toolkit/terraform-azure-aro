#!/usr/bin/env bash

set -e

INPUT=$(tee)

BIN_DIR=$(echo "${INPUT}" | grep "bin_dir" | sed -E 's/.*"bin_dir": ?"([^"]+)".*/\1/g')

echo "Bin dir: ${BIN_DIR}"
echo "Input: ${INPUT}"

eval "$(echo "${INPUT}" | ${BIN_DIR}/jq -r '@sh "CLUSTER_NAME=\(.cluster_name) RESOURCE_GROUP_NAME=\(.resource_group_name) SUBSCRIPTION_ID=\(.subscription_id) TENANT_ID=\(.tenant_id) CLIENT_ID=\(.client_id) CLIENT_SECRET=\(.client_secret) TOKEN=\(.access_token) TMP_DIR=\(.tmp_dir)"')"

echo "SUBSCRIPTION_ID=${SUBSCRIPTION_ID}, RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME}"

API_VERSION="2020-04-30"

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp/aro"
fi
mkdir -p "${TMP_DIR}"

#CLIENT_ID=""
#CLIENT_SECRET=""
#TENANT_ID=""

if [[ -z "${TOKEN}" ]]; then
  TOKEN=$(curl -s -X POST -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&resource=https%3A%2F%2Fmanagement.azure.com%2F" "https://login.microsoftonline.com/${TENANT_ID}/oauth2/token" | ${BIN_DIR}/jq -r '.access_token')
fi

URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.RedHatOpenshift/openShiftClusters/${CLUSTER_NAME}?api-version=${API_VERSION}"

echo "Getting cluster info: ${URL}"
curl -s -X GET \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  "${URL}" | \
  ${BIN_DIR}/jq '{id: .id, name: .name, location: .location, state: .properties.provisioningState, serverUrl: .properties.apiserverProfile.url, publicSubdomain: .properties.clusterProfile.domain, consoleUrl: .properties.consoleProfile.url}' > "${TMP_DIR}/output.json"

echo "Cluster output"
cat "${TMP_DIR}/output.json"

AUTH_URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.RedHatOpenShift/openShiftClusters/${CLUSTER_NAME}/listCredentials?api-version=${API_VERSION}"

echo "Getting cluster auth info: ${AUTH_URL}"
curl -s -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "" \
  "${AUTH_URL}" > "${TMP_DIR}/credentials.json"

jq -s '.[0] * .[1]' "${TMP_DIR}/output.json" "${TMP_DIR}/credentials.json"
