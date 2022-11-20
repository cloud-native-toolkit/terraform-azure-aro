#!/usr/bin/env bash

set -e

INPUT=$(tee)

BIN_DIR=$(echo "${INPUT}" | grep "bin_dir" | sed -E 's/.*"bin_dir": ?"([^"]+)".*/\1/g')

#echo "Bin dir: ${BIN_DIR}"
#echo "Input: ${INPUT}"

eval "$(echo "${INPUT}" | ${BIN_DIR}/jq -r '@sh "CLUSTER_NAME=\(.cluster_name) RESOURCE_GROUP_NAME=\(.resource_group_name) SUBSCRIPTION_ID=\(.subscription_id) TENANT_ID=\(.tenant_id) CLIENT_ID=\(.client_id) CLIENT_SECRET=\(.client_secret) TOKEN=\(.access_token) TMP_DIR=\(.tmp_dir)"')"

#echo "SUBSCRIPTION_ID=${SUBSCRIPTION_ID}, RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME}"

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

STATE="Creating"
while [[ "${STATE}" == "Creating" ]]; do
  curl -s -X GET \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    "${URL}" | \
    ${BIN_DIR}/jq '{id: .id, name: .name, location: .location, state: .properties.provisioningState, serverUrl: .properties.apiserverProfile.url, publicSubdomain: .properties.clusterProfile.domain, consoleUrl: .properties.consoleProfile.url, errorMessage: .error.message, errorCode: .error.code, result: .}' > "${TMP_DIR}/output.json"

  STATE=$(cat "${TMP_DIR}/output.json" | jq -r ".state")
  if [[ "${STATE}" == "Creating" ]]; then
    sleep 300
  fi
done

AUTH_URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.RedHatOpenShift/openShiftClusters/${CLUSTER_NAME}/listCredentials?api-version=${API_VERSION}"

if [[ "${STATE}" != "Failed" ]]; then
  curl -s -X POST \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "" \
    "${AUTH_URL}" > "${TMP_DIR}/credentials.json"
else
  cat "${TMP_DIR}/output.json" >&2
  exit 1
fi

#jq -s '.[0] * .[1]' "${TMP_DIR}/output.json" "${TMP_DIR}/credentials.json"

# Terraform external data output can only be a single layer JSON so need to extract values from output.json
ID=$(cat "${TMP_DIR}/output.json" | jq -r ".id")
URL=$(cat "${TMP_DIR}/output.json" | jq -r ".serverUrl")
VERSION=$(cat "${TMP_DIR}/output.json" | jq -r ".result.properties.clusterProfile.version")
CONSOLE=$(cat "${TMP_DIR}/output.json" | jq -r ".result.properties.consoleProfile.url")
USER=$(cat "${TMP_DIR}/credentials.json" | jq -r ".kubeadminUsername")
PWD=$(cat "${TMP_DIR}/credentials.json" | jq -r ".kubeadminPassword")
jq --null-input \
    --arg id "${ID}" \
    --arg url "${URL}" \
    --arg user "${USER}" \
    --arg pwd "${PWD}" \
    --arg version "${VERSION}" \
    --arg console "${CONSOLE}" \
    '{"id": $id, "serverUrl": $url, "kubeadminUsername": $user, "kubeadminPassword": $pwd, "version": $version, "consoleUrl": $console}'
