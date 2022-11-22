#!/usr/bin/env bash

# Find SP id if it exists
SP_ID=$(az ad sp list --query "[].{name:displayName,id:id}" --all | ${BIN_DIR}/jq -r ".[] | select(.name==\"${SP_NAME}\") | .id")

# Delete SP if it exists (based upon above query)
if [[ -n $SP_ID ]]; then
  az ad sp delete --id ${SP_ID}
fi

# Remove SP_FILE if it exists
if [[ -f ${SP_FILE} ]]; then
  rm ${SP_FILE}
fi