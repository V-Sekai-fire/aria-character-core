#!/bin/sh
set -e

# Environment variables to be provided by docker-compose, sourced from GitHub Actions secrets
# OPENBAO_ADDR - e.g., http://openbao:8200
# OPENBAO_APPROLE_ROLE_ID
# OPENBAO_APPROLE_SECRET_ID
# OPENBAO_S3_CRED_PATH - e.g., secret/data/seaweedfs/s3config

S3_CONFIG_OUTPUT_DIR="/etc/seaweedfs"
S3_CONFIG_FILE_PATH="${S3_CONFIG_OUTPUT_DIR}/s3.json"

echo "Attempting to fetch OpenBao client token..."
# Get OpenBao client token using AppRole
CLIENT_TOKEN=$(curl -s --request POST \
  --data "{\"role_id\": \"${OPENBAO_APPROLE_ROLE_ID}\", \"secret_id\": \"${OPENBAO_APPROLE_SECRET_ID}\"}" \
  ${OPENBAO_ADDR}/v1/auth/approle/login | jq -r .auth.client_token)

if [ -z "${CLIENT_TOKEN}" ] || [ "${CLIENT_TOKEN}" = "null" ]; then
  echo "Error: Failed to retrieve OpenBao client token. Check AppRole credentials and OpenBao connectivity."
  exit 1
fi
echo "Successfully fetched OpenBao client token."

# Fetch the S3 configuration JSON from OpenBao
echo "Fetching S3 configuration from OpenBao path: ${OPENBAO_S3_CRED_PATH}"
S3_JSON_CONFIG=$(curl -s --header "X-OpenBao-Token: ${CLIENT_TOKEN}" \
  ${OPENBAO_ADDR}/v1/${OPENBAO_S3_CRED_PATH} | jq -r .data.data.s3_json_content)

if [ -z "${S3_JSON_CONFIG}" ] || [ "${S3_JSON_CONFIG}" = "null" ]; then
  echo "Error: Failed to retrieve S3 JSON configuration from OpenBao or content is empty."
  echo "Please ensure the secret at '${OPENBAO_S3_CRED_PATH}' in OpenBao contains a field named 's3_json_content' with the full s3.json as its value."
  exit 1
fi

echo "Successfully fetched S3 configuration from OpenBao."

# Create the directory and write the s3.json file
mkdir -p ${S3_CONFIG_OUTPUT_DIR}
echo "${S3_JSON_CONFIG}" > ${S3_CONFIG_FILE_PATH}

echo "s3.json has been written to ${S3_CONFIG_FILE_PATH}"

# Keep the container running if this volume is directly mounted by SeaweedFS
# and SeaweedFS needs the file to be present continuously from this container.
# However, for a one-shot generation, this script would just exit.
# If SeaweedFS starts after this, it will pick up the generated file.
# For CI, this one-shot generation is typical.

# If this container needs to keep the volume populated and running:
# exec tail -f /dev/null
