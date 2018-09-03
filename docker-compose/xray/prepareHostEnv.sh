#!/bin/bash
# This file is for preparing all the needed files and directories on the host.

source ./.env

SCRIPT_DIR=$(dirname $0)
OS_NAME=$(uname)

errorExit () {
    echo; echo "ERROR: $1"; echo
    exit 1
}

if [ "${OS_NAME}" = "Linux" ] && [ "$EUID" != 0 ]; then
    errorExit "This script must be run as root or with sudo"
fi

echo "Creating ${XRAY_MOUNT_ROOT}"
mkdir -p ${XRAY_MOUNT_ROOT}/xray

echo "Setting needed ownerships on ${XRAY_MOUNT_ROOT}"
chown -R ${XRAY_USER_ID}:${XRAY_USER_ID} ${XRAY_MOUNT_ROOT}/xray || errorExit "Setting ownership of ${XRAY_MOUNT_ROOT}/xray to ${XRAY_USER_ID} failed"
