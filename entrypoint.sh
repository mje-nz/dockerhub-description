#!/bin/sh
set -euo pipefail
IFS=$'\n\t'

# Set the default path to README.md
README_FILEPATH=${README_FILEPATH:="./README.md"}

# Acquire a token for the Docker Hub API
echo "Acquiring token"
LOGIN_PAYLOAD="{\"username\": \"${DOCKERHUB_USERNAME}\", \"password\": \"${DOCKERHUB_PASSWORD}\"}"
OUTPUT=$(curl -s -H "Content-Type: application/json" -X POST -d "${LOGIN_PAYLOAD}" https://hub.docker.com/v2/users/login/)
if ! TOKEN=$(echo "${OUTPUT}" | jq -e -r .token); then
  echo "Failed: $(echo "${OUTPUT}" | jq -e -r .detail)"
  exit 1
fi

# Send a PATCH request to update the description of the repository
echo "Sending PATCH request"
REPO_URL="https://hub.docker.com/v2/repositories/${DOCKERHUB_REPOSITORY}/"
OUTPUT=$(curl -s --write-out "%{response_code}" -H "Authorization: JWT ${TOKEN}" -X PATCH --data-urlencode "full_description@${README_FILEPATH}" "${REPO_URL}")
BODY="${OUTPUT::-3}"
RESPONSE_CODE=${OUTPUT:(-3)}

if [ "${RESPONSE_CODE}" -ne 200 ]; then
  echo "Received response code: ${RESPONSE_CODE}"
  echo "${BODY}"
  exit 1
fi

echo "Done"
