#!/bin/bash
# This file is for preparing all the needed files and directories on the host.

SCRIPT_DIR=$(dirname $0)
OS_NAME=$(uname)

errorExit () {
    echo; echo "ERROR: $1"; echo
    exit 1
}

if [ "${OS_NAME}" = "Linux" ] && [ "$EUID" != 0 ]; then
    errorExit "This script must be run as root or with sudo"
fi

if [ ! -f ./.env ]; then
    errorExit ".env file does not exist in $SCRIPT_DIR"
fi

source ./.env

if [ ! -d ${XRAY_MOUNT_ROOT}/xray ]; then
    echo "Creating ${XRAY_MOUNT_ROOT}/xray"
    mkdir -p ${XRAY_MOUNT_ROOT}/xray
    mkdir -p ${XRAY_MOUNT_ROOT}/rabbitmq/conf
    mkdir -p ${XRAY_MOUNT_ROOT}/rabbitmq/logs
    cp rabbitmq.conf ${XRAY_MOUNT_ROOT}/rabbitmq/conf
fi

if [ $(stat -c '%u' ${XRAY_MOUNT_ROOT}/xray) != "${XRAY_USER_ID}" ] || [ $(stat -c '%g' ${XRAY_MOUNT_ROOT}/xray) != "${XRAY_USER_ID}" ]; then
    echo "Setting needed ownerships on ${XRAY_MOUNT_ROOT}/xray"
    chown -R ${XRAY_USER_ID}:${XRAY_USER_ID} ${XRAY_MOUNT_ROOT}/xray || errorExit "Setting ownership of ${XRAY_MOUNT_ROOT}/xray to ${XRAY_USER_ID} failed"
fi

echo "Done!"
