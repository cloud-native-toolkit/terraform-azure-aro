#!/usr/bin/env bash

# Create service principal
SP_DATA=$(az ad sp create-for-rbac --name "${SP_NAME}") 

# Extract details
SP_CLIENT_ID=$(echo "${SP_DATA}" | "${BIN_DIR}"/jq -r '.appId')
SP_CLIENT_SECRET=$(echo "${SP_DATA}" | "${BIN_DIR}"/jq -r '.password')
SP_OBJECT_ID=$(az ad sp show --id "${SP_CLIENT_ID}" | "${BIN_DIR}"/jq -r '.id')

# Add object id to json file
echo "${SP_DATA}" | ${BIN_DIR}/jq ".id += \"${SP_OBJECT_ID}\"" > ${OUT_FILE}

