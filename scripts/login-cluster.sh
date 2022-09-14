#!/usr/bin/env bash

set -e

INPUT=$(tee)

BIN_DIR=$(echo "${INPUT}" | grep "bin_dir" | sed -E 's/.*"bin_dir": ?"([^"]+)".*/\1/g')

eval "$(echo "${INPUT}" | ${BIN_DIR}/jq -r '@sh "SERVER_URL=\(.server_url) USERNAME=\(.username) PASSWORD=\(.password) KUBECONFIG=\(.kubeconfig)"')"

oc login ${SERVER_URL} --username=${USERNAME} --password=${PASSWORD} --kubeconfig=${KUBECONFIG} --insecure-skip-tls-verify 1> /dev/null 2> /dev/null

SERVER=$(echo ${SERVER_URL} | sed 's/https\:\/\///g' | sed 's/\./-/g' | sed 's/\///g')

TOKEN=$(cat "${KUBECONFIG}" | yq eval ".users[] | select(.name == \"*kube:admin/${SERVER}\") | .user.token")

jq --null-input \
 --arg token "${TOKEN}" \
 '{"token": $token}'