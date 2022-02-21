#!/usr/bin/env bash

SERVER_URL="$1"
USERNAME="$2"

if [[ -z "${SERVER_URL}" ]] || [[ -z "${USERNAME}" ]]; then
  echo "usage: login-cluster.sh SERVER_URL USERNAME"
  exit 1
fi

if [[ -z "${PASSWORD}" ]]; then
  echo "PASSWORD must be provided as an environment variable"
  exit 1
fi

oc login ${SERVER_URL} --username=${USERNAME} --password=${PASSWORD} 1> /dev/null 2> /dev/null
