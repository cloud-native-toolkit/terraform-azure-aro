#!/usr/bin/env bash

set -e

INPUT=$(tee)
OUTPUT=$(echo "${INPUT}" | grep "rp_data_file" | sed -E 's/.*"rp_data_file": ?"([^"]+)".*/\1/g')

RP_PROVIDER=$(az ad sp list --display-name "Azure Red Hat OpenShift RP" --query [0].id -o tsv)

if [[ ${RP_PROVIDER} == "" ]]; then
  MSG="ERROR: Azure Red Hat OpenShift RP not found"
else
  MSG="Successfully obtained Azure Red Hat OpenShift Resource Provider"
fi

if [[ $OUTPUT == "" ]]; then
 OUTPUT="/dev/null"
fi

printf '{\n"id":"%s",\n"message":"%s"\n}\n' "${RP_PROVIDER}" "${MSG}" | tee ${OUTPUT}