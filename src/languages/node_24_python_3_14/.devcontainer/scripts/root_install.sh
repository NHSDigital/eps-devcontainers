#!/usr/bin/env bash
set -e

# store version info in VERSION.txt for reference
echo "VERSION=${BASE_VERSION}" > "${SCRIPTS_DIR}/VERSION.txt"
echo "CONTAINER_NAME=${CONTAINER_NAME}" >> "${SCRIPTS_DIR}/VERSION.txt"
