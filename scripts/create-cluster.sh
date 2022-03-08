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
VM_SIZE="${VM_SIZE:-Standard_D4s_v3}"
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

PULL_SECRET_ARG=""
if [[ -n "${PULL_SECRET}" ]]; then
  PULL_SECRET_ARG="--pull-secret '${PULL_SECRET}'"
fi

az provider register -n Microsoft.RedHatOpenShift --wait
az provider register -n Microsoft.Compute --wait
az provider register -n Microsoft.Storage --wait
az provider register -n Microsoft.Authorization --wait

az account set --subscription "${SUBSCRIPTION_ID}"

az login --service-principal -u "${CLIENT_ID}" -p "${CLIENT_SECRET}" -t "${TENANT_ID}"

az aro create \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${CLUSTER_NAME}" \
  --master-subnet "${MASTER_SUBNET_ID}" \
  --worker-subnet "${WORKER_SUBNET_ID}" \
  --apiserver-visibility "${VISIBILITY}" \
  --ingress-visibility "${VISIBILITY}" \
  --worker-count "${WORKER_COUNT}" ${PULL_SECRET_ARG}
