#!/usr/bin/env bash

# Parse output from sp create 
if [[ ! -f ${SP_FILE} ]]; then
  # allow normal exit to cater for calling script multiple times
  echo "Service principal file does not exist"
  exit 0;
elif [[ ! -f ${BIN_DIR}/jq ]]; then
  echo "ERROR: ${BIN_DIR}/jq not found"
  exit 1;
else
  ID=$("${BIN_DIR}"/jq -r '.id' "${SP_FILE}")
fi

# Check if SP exists and delete it if does
if [[ $(az ad sp show --id "${ID}" | grep "exist") == "" ]]; then
  az ad sp delete --id ${ID}
fi

# Remove SP_FILE (double check file exists first)
if [[ -f ${SP_FILE} ]]; then
  rm ${SP_FILE}
fi