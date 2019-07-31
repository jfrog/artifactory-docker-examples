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

if [ ! -d ${XRAY_MOUNT_ROOT}/xray1 ]; then
    echo "Creating ${XRAY_MOUNT_ROOT}/xray1"
    mkdir -p ${XRAY_MOUNT_ROOT}/xray1/security
fi

if [ $(stat -c '%u' ${XRAY_MOUNT_ROOT}/xray1) != "${XRAY_USER_ID}" ] || [ $(stat -c '%g' ${XRAY_MOUNT_ROOT}/xray1) != "${XRAY_USER_ID}" ]; then
    echo "Setting needed ownerships on ${XRAY_MOUNT_ROOT}/xray1"
    chown -R ${XRAY_USER_ID}:${XRAY_USER_ID} ${XRAY_MOUNT_ROOT}/xray1 || errorExit "Setting ownership of ${XRAY_MOUNT_ROOT}/xray1 to ${XRAY_USER_ID} failed"
    cp -Rp ${XRAY_MOUNT_ROOT}/xray1 ${XRAY_MOUNT_ROOT}/xray2
fi

# set master.key
MASTER_KEY="c579934107af996b860537b309711b099fa0445f92715dd9e0cbe304319c9e0d"
# use the same master.key for both instances
echo $MASTER_KEY > ${XRAY_MOUNT_ROOT}/xray1/security/master.key
cp ${XRAY_MOUNT_ROOT}/xray1/security/master.key ${XRAY_MOUNT_ROOT}/xray2/security/master.key

# start mongodb
docker-compose -f xray-ha.yml up -d mongodb

# create users in mongodb
cat createMongoUsers.js | docker exec -i xray-mongodb mongo

docker-compose -f xray-ha.yml up -d

echo "Done!"