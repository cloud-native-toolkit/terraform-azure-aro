#!/usr/bin/env bash
#
# This script reads the output file from the create-sp.sh script and returns as json variables
# We read in existing json and remap to different variable names

set -e

INPUT=$(tee)

# echo ${INPUT}

# Get bin_dir to be able to use jq
BIN_DIR=$(echo "${INPUT}" | grep "bin_dir" | sed -E 's/.*"bin_dir": ?"([^"]+)".*/\1/g')

MSG=""
APP_ID=""
SP_NAME=""
SECRET=""
TENANT=""
ID=""

if [[ $BIN_DIR == "" ]]; then
  MSG="ERROR: bin_dir not set"
elif [[ ! -f ${BIN_DIR}/jq ]]; then
  MSG="ERROR: yq not found in ${BIN_DIR}"
else
  # Parse input
  eval "$(echo "${INPUT}" | "${BIN_DIR}"/jq -r '@sh "SP_FILE=\(.sp_data_file)"')"

  if [[ $SP_FILE == "" ]]; then
    MSG="ERROR: Service principal file not provided"
  elif [[ $SP_FILE == null ]]; then
    MSG="ERROR: sp_data_file not set"
  else
    # Check if file exists, if not, return empty values
    if [[ -f "${SP_FILE}" ]]; then
        APP_ID=$("${BIN_DIR}"/jq -r '.appId' "${SP_FILE}")
        SP_NAME=$("${BIN_DIR}"/jq -r '.displayName' "${SP_FILE}")
        SECRET=$("${BIN_DIR}"/jq -r '.password' "${SP_FILE}")
        TENANT=$("${BIN_DIR}"/jq -r '.tenant' "${SP_FILE}")
        ID=$("${BIN_DIR}"/jq -r '.id' "${SP_FILE}")
        MSG="Successfully parsed service principal details"
    else
        MSG="ERROR: Unable to find ${SP_FILE}"
    fi
  fi
fi

printf '{\n"id":"%s",\n"client_id":"%s",\n"client_secret":"%s",\n"tenant_id":"%s",\n"message":"%s"\n}\n' "$ID" "$APP_ID" "$SECRET" "$TENANT" "$MSG"