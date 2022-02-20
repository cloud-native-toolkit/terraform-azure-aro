#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

SUBSCRIPTION_ID="$1"
RESOURCE_GROUP_NAME="$2"
CLUSTER_NAME="$3"
REGION="$4"
VNET_ID="$5"
MASTER_CIDR="$6"
WORKER_CIDR="$7"

OPENSHIFT_VERSION="${OPENSHIFT_VERSION:-4.8}"
VM_SIZE="${VM_SIZE:-Standard_D4s_v3}"
MASTER_VM_SIZE="${MASTER_VM_SIZE:-$VM_SIZE}"

OS_TYPE="${OS_TYPE:-Linux}"
MASTER_COUNT="${MASTER_COUNT:-3}"
INFRA_COUNT="${INFRA_COUNT:-2}"
COMPUTE_COUNT="${COMPUTE_COUNT:-4}"

API_VERSION="2019-04-30"

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp/aro"
fi
mkdir -p "${TMP_DIR}"

#CLIENT_ID=""
#CLIENT_SECRET=""
#TENANT_ID=""

echo "Getting token"
TOKEN=$(curl -s -X POST -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&resource=https%3A%2F%2Fmanagement.azure.com%2F" "https://login.microsoftonline.com/${TENANT_ID}/oauth2/token")

echo "Got token: ${TOKEN}"

URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.ContainerService/openShiftManagedClusters/${CLUSTER_NAME}?api-version=${API_VERSION}"

echo "{}" | ${BIN_DIR}/jq
cat > "${TMP_DIR}/config.json" << EOF
{
  "location": "${REGION}",
  "tags": {},
  "properties": {
    "openShiftVersion": "v${OPENSHIFT_VERSION}",
    "networkProfile": {
      "vnetId": "${VNET_ID}"
    },
    "masterPoolProfile": {
      "name": "master",
      "count": ${MASTER_COUNT},
      "vmSize": "${VM_SIZE}",
      "osType": "${OS_TYPE}",
      "subnetCidr": "${MASTER_CIDR}"
    },
    "agentPoolProfiles": [
      {
        "name": "infra",
        "role": "infra",
        "count": ${INFRA_COUNT},
        "vmSize": "${VM_SIZE}",
        "osType": "${OS_TYPE}",
        "subnetCidr": "${WORKER_CIDR}"
      },
      {
        "name": "compute",
        "role": "compute",
        "count": ${COMPUTE_COUNT},
        "vmSize": "${VM_SIZE}",
        "osType": "${OS_TYPE}",
        "subnetCidr": "${WORKER_CIDR}"
      }
    ],
    "routerProfiles": [
      {
        "name": "default"
      }
    ],
    "authProfile": {
      "identityProviders": [
        {
          "name": "Azure AD",
          "provider": {
            "kind": "AADIdentityProvider",
            "clientId": "${CLIENT_ID}",
            "secret": "${CLIENT_SECRET}",
            "tenantId": "${TENANT_ID}",
            "customerAdminGroupId": "${AUTH_GROUP_ID}"
          }
        }
      ]
    }
  }
}
EOF

curl -s -X PUT \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  "${URL}" \
  --data-binary "@${TMP_DIR}/config.json"
