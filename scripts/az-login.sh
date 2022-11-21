#!/usr/bin/env bash

# Check if already logged in
az account show > /dev/null 2>&1
RESULT=$(echo $?)

# Try to determine client secret if not provided to script
if [[ -z $CLIENT_SECRET ]]; then
  if [[ -n $ARM_CLIENT_SECRET ]]; then
    CLIENT_SECRET=$(echo $ARM_CLIENT_SECRET)
  elif [[ -n $TF_VAR_client_secret ]]; then
    CLIENT_SECRET=$(echo $TF_VAR_client_secret)
  else
    CLIENT_SECRET=""    # This will cause the next section to fail if not already logged in
fi


if [[ $RESULT -ne 0 ]]; then
  if [[ $CLIENT_ID == "" ]] || [[ $CLIENT_SECRET == "" ]] || [[ $TENANT_ID == "" ]] || [[ $SUBSCRIPTION_ID == "" ]]; then
    echo "ERROR: Please provide SUBSCRIPTION_ID, CLIENT_ID, CLIENT_SECRET and TENANT_ID as environment variables to login"
    echo "CLIENT_ID = $CLIENT_ID, CLIENT_SECRET = $CLIENT_SECRET, TENANT_ID = $TENANT_ID, SUBSCRIPTION_ID = $SUBSCRIPTION_ID"
    exit 1;
  else
    az login --service-principal -u "${CLIENT_ID}" -p "${CLIENT_SECRET}" -t "${TENANT_ID}"
    az account set --subscription "${SUBCRIPTION_ID}"
    az account show > ${OUTPUT}
  fi
else
  # Already logged in
  echo "Using existing login"
fi