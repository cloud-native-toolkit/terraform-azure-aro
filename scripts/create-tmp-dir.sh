#!/usr/bin/env bash

set -e

INPUT=$(tee)
TMP_DIR=$(echo "${INPUT}" | grep "tmp_dir" | sed -E 's/.*"tmp_dir": ?"([^"]+)".*/\1/g')

if [[ -z "${TMP_DIR}" ]]; then
  MSG = "ERROR: No tmp_dir provided"
else
  mkdir -p "${TMP_DIR}"
fi

printf '{\n"path":"%s",\n"message":"%s"\n}\n' "${TMP_DIR}" "${MSG}"

