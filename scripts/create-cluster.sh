#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

SUBSCRIPTION_ID="$1"
RESOURCE_GROUP_NAME="$2"
RESOURCE_GROUP_ID="$3"
CLUSTER_NAME="$4"
REGION="$5"
VNET_ID="$6"
MASTER_SUBNET_ID="$7"
WORKER_SUBNET_ID="$8"
DOMAIN="$9"

OPENSHIFT_VERSION="${OPENSHIFT_VERSION:-4.8.11}"
VM_SIZE="${VM_SIZE:-Standard_D8s_v3}"
MASTER_VM_SIZE="${MASTER_VM_SIZE:-Standard_D8s_v3}"

OS_TYPE="${OS_TYPE:-Linux}"
WORKER_COUNT="${COMPUTE_COUNT:-4}"
DISK_SIZE="${DISK_SIZE:-128}"

VISIBILITY="${VISIBILITY:-Public}"

API_VERSION="2020-04-30"

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp/aro"
fi
mkdir -p "${TMP_DIR}"

#CLIENT_ID=""
#CLIENT_SECRET=""
#TENANT_ID=""

#PULL_SECRET=""

echo "Getting token"
TOKEN=$(curl -s -X POST -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&resource=https%3A%2F%2Fmanagement.azure.com%2F" "https://login.microsoftonline.com/${TENANT_ID}/oauth2/token" | ${BIN_DIR}/jq -r '.access_token')

echo "Got token: ${TOKEN}"

URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.RedHatOpenshift/openShiftClusters/${CLUSTER_NAME}?api-version=${API_VERSION}"

cat > "${TMP_DIR}/config.json" << EOF
{
  "location": "${REGION}",
  "tags": {},
  "properties": {
    "clusterProfile": {
      "resourceGroupId": "${RESOURCE_GROUP_ID}",
      "domain": "${DOMAIN}"
    },
    "consoleProfile": {},
    "servicePrincipalProfile": {
      "clientId": "${CLIENT_ID}",
      "clientSecret": "${CLIENT_SECRET}"
    },
    "networkProfile": {
      "podCidr": "10.128.0.0/14",
      "serviceCidr": "172.30.0.0/16"
    },
    "masterProfile": {
      "vmSize": "${MASTER_VM_SIZE}",
      "subnetId": "${MASTER_SUBNET_ID}"
    },
    "workerProfiles": [
      {
        "name": "${CLUSTER_NAME}-worker",
        "vmSize": "${VM_SIZE}",
        "diskSizeGB": ${DISK_SIZE},
        "subnetId": "${WORKER_SUBNET_ID}",
        "count": ${WORKER_COUNT}
      }
    ],
    "apiserverProfile": {
      "visibility": "${VISIBILITY}"
    },
    "ingressProfiles": [
      {
        "name": "default",
        "visibility": "${VISIBILITY}"
      }
    ]
  }
}
EOF

if [[ -n "${PULL_SECRET}" ]]; then
  jq --arg PULL_SECRET "${PULL_SECRET}" '.properties.clusterProfile.pullSecret = $PULL_SECRET' "${TMP_DIR}/config.json" > "${TMP_DIR}/config.json.tmp"
  cp "${TMP_DIR}/config.json.tmp" "${TMP_DIR}/config.json"
  rm "${TMP_DIR}/config.json.tmp"
fi

OUTPUT=$(curl -s -X PUT \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  "${URL}" \
  --data-binary "@${TMP_DIR}/config.json")

echo "$OUTPUT"

