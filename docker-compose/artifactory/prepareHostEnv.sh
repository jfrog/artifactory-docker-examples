#!/bin/bash

# This file is for preparing all the needed files and directories on the host.
# These directories are mounted into the Docker containers.

SCRIPT_DIR=$(dirname $0)
DEFAULT_ROOT_DATA_DIR=/data
LINUX_ROOT_DATA_DIR=${DEFAULT_ROOT_DATA_DIR}
MAC_DEFAULT_ROOT_DATA_DIR=~/.artifactory
OS_NAME=$(uname)
ARTIFACTORY_USER_ID=1030
NGINX_USER_ID=104
NGINX_GROUP_ID=107

errorExit () {
    echo; echo "ERROR: $1"; echo
    exit 1
}

usage () {

    cat << END_USAGE

$0 - script for preparing the needed directories on the local host for mounting into the Artifactory Docker containers

Usage: $0 options
Supported options
-t   : (Required) Deployment type. 'pro', 'oss', 'ha' or 'ha-shared-data'
       - pro            : Single Pro node
       - oss            : Single OSS node
       - ha             : HA with two nodes
       - ha-shared-data : HA that uses a shared data mount
       - oss            : Single OSS node
-d   : Custom root data directory (defaults to /data)
-c   : Clean local data directory. Delete the data directory on the host before creating the new ones
-f   : Force removal if -c is passed (do not prompt)
-h   : Show this usage

Examples
Prepare directories for Artifactory pro with default data directory
Start : sudo $0 -t pro -c

Prepare directories for Artifactory OSS with default data directory
Start : sudo $0 -t oss -c

Prepare a default HA deployment directories
Start : sudo $0 -t ha -c

END_USAGE

    exit 1
}

setOS () {
    if [ ${OS_NAME} != "Darwin" ] && [ ${OS_NAME} != "Linux" ]; then
        echo "This script can run on Mac or Linux only!"
    fi

    # On Mac, set DEFAULT_ROOT_DATA_DIR to ~/.artifactory
    if [ "${OS_NAME}" = "Darwin" ]; then
        echo "On Mac. Setting DEFAULT_ROOT_DATA_DIR to $MAC_DEFAULT_ROOT_DATA_DIR"
        DEFAULT_ROOT_DATA_DIR=${MAC_DEFAULT_ROOT_DATA_DIR}
    fi
}

validateSudo () {
    if [ "${OS_NAME}" = "Linux" ] && [ "$EUID" != 0 ]; then
        errorExit "This script must be run as root or with sudo"
    fi
}

# Process command line options. See usage above for supported options
processOptions() {
    while getopts ":t:d:cfh" opt; do
        case $opt in
            t)  # Run type
                TYPE=$OPTARG
                if [ ${TYPE} != "pro" ] && [ ${TYPE} != "ha" ] && [ ${TYPE} != "ha-shared-data" ] && [ ${TYPE} != "oss" ]; then
                    echo "ERROR: Deployment type ${TYPE} is not supported"
                    usage
                fi
            ;;
            d)  # Data dir
                ROOT_DATA_DIR=$OPTARG
                echo "Using a custom root data dir: $ROOT_DATA_DIR"
            ;;
            c)  # Clean
                CLEAN=true
            ;;
            f)  # Force
                FORCE=true
            ;;
            h)  # Usage
                usage
            ;;
            \?) # Unsupported
                echo "ERROR: Option $OPTARG is not supported!"
                usage
            ;;
        esac
    done

    # Make sure mandatory parameters are set
    if [ -z "${TYPE}" ]; then
        echo "You must pass a deployment type (-t <pro|ha|ha-shared-data|oss>)"
        usage
    fi

    # Set ROOT_DATA_DIR
    if [ -z "${ROOT_DATA_DIR}" ]; then
        ROOT_DATA_DIR=${DEFAULT_ROOT_DATA_DIR}
    fi
}

cleanDataDir () {
    if [ "${CLEAN}" = "true" ] && [ -d ${ROOT_DATA_DIR} ]; then
        local sure='n'

        if [ "${FORCE}" = "true" ]; then
            sure='y'
        else
            read -p "Are you sure you want to remove existing ${ROOT_DATA_DIR} [y/n]: " sure
        fi
        if [ "${sure}" = "y" ]; then
            echo "Removing old ${ROOT_DATA_DIR}"
            rm -rf ${ROOT_DATA_DIR}
        fi
    fi
}

createDirectories () {
    echo "Creating ${ROOT_DATA_DIR}"
    mkdir -p ${ROOT_DATA_DIR}/postgresql

    # Check if this is the first creation of the directories
    if [ ! -d ${ROOT_DATA_DIR}/artifactory ]; then
        echo "First setup. Setting FIRST_SETUP=true"
        FIRST_SETUP=true
    fi

    if [ "${TYPE}" = "pro" ] || [  "${TYPE}" == "oss" ]; then
        mkdir -p ${ROOT_DATA_DIR}/artifactory/etc
    else
        mkdir -p ${ROOT_DATA_DIR}/artifactory/node{1,2}/etc
        if [ "${TYPE}" = "ha-shared-data" ]; then
            mkdir -p ${ROOT_DATA_DIR}/artifactory/{ha,backup}
        fi
    fi
    mkdir -p ${ROOT_DATA_DIR}/nginx/conf.d
    mkdir -p ${ROOT_DATA_DIR}/nginx/logs
    mkdir -p ${ROOT_DATA_DIR}/nginx/ssl
}

copyFiles () {
    echo "Copying needed files to directories"

    echo "Artifactory configuration files"
    if [ "${TYPE}" = "pro" ] || [ "${TYPE}" = "oss" ]; then
        cp -fr ${SCRIPT_DIR}/../../files/access ${ROOT_DATA_DIR}/artifactory/ || errorExit "Copy failed"
    else
        cp -fr ${SCRIPT_DIR}/../../files/access ${ROOT_DATA_DIR}/artifactory/node1/ || errorExit "Copy failed"
        cp -fr ${SCRIPT_DIR}/../../files/access ${ROOT_DATA_DIR}/artifactory/node2/ || errorExit "Copy failed"
    fi

    # Copy the binarystore.xml which has configuration for no-shared storage
    if [ "${TYPE}" = "ha" ]; then
        cp -f ${SCRIPT_DIR}/../../files/binarystore.xml ${ROOT_DATA_DIR}/artifactory/node1/etc || errorExit "Copy failed"
    fi

    local type=${TYPE}
    if [ ${type} = "ha-shared-data" ]; then type=ha; fi

    echo "Nginx Artifactory configuration"
    cp -fr ${SCRIPT_DIR}/../../files/nginx/conf.d/${type}/* ${ROOT_DATA_DIR}/nginx/conf.d/ || errorExit "Copy failed"
}

setPermissions () {
    # Fix directories ownerships only on Linux
    if [ "${OS_NAME}" == "Linux" ]; then
        echo "Setting needed ownerships on ${ROOT_DATA_DIR}"
        chown -R ${ARTIFACTORY_USER_ID}:${ARTIFACTORY_USER_ID} ${ROOT_DATA_DIR}/artifactory || errorExit "Setting ownership of ${ROOT_DATA_DIR}/artifactory to ${ARTIFACTORY_USER_ID} failed"
        chown -R ${NGINX_USER_ID}:${NGINX_GROUP_ID} ${ROOT_DATA_DIR}/nginx || errorExit "Setting ownership of ${ROOT_DATA_DIR}/nginx ${NGINX_USER_ID}:${NGINX_GROUP_ID} failed"
    fi

    # Give wide permissions on Mac (to support the non-root Artifactory and Nginx containers)
    if [ "${OS_NAME}" == "Darwin" ] && [ "${FIRST_SETUP}" == "true" ]; then
        echo "Setting 777 permissions on ${ROOT_DATA_DIR}/artifactory"
        chmod -R 777 ${ROOT_DATA_DIR}/artifactory || errorExit "Setting 777 permissions on ${ROOT_DATA_DIR}/artifactory failed"
    fi
}

showNotes () {

    if [ "${TYPE}" = "pro" ]; then
        cat << PRO_NOTES

======================================
IMPORTANT
- Before starting, it is recommended to place the license file(s) (artifactory.lic) in the Artifactory etc directory
  - Artifactory pro:   ${ROOT_DATA_DIR}/artifactory/etc
- The access keys used in these examples SHOULD NOT be used for production!
PRO_NOTES
    fi

    if [ "${TYPE}" = "ha" ]; then
        cat <<HA_NOTES
======================================
IMPORTANT
- Before starting, it is recommended to place the license file(s) (artifactory.lic) in the Artifactory etc directory of the primary node
  - Artifactory HA :   ${ROOT_DATA_DIR}/artifactory/node1/etc
                       ${ROOT_DATA_DIR}/artifactory/node2/etc
- The access keys used in these examples SHOULD NOT be used for production!
HA_NOTES
    fi


    if [ "${TYPE}" = "oss" ]; then
        cat << OSS_NOTES

======================================

INSTALLATION DIRECTORY
  - Artifactory OSS:   ${ROOT_DATA_DIR}/artifactory/etc
- The access keys used in these examples SHOULD NOT be used for production!
OSS_NOTES
    fi

    local extra_msg=""
    if [ "$DEFAULT_ROOT_DATA_DIR" != "$ROOT_DATA_DIR" ]; then
        extra_msg="- You changed the default root data directory to ${ROOT_DATA_DIR}, you have to update the docker-compose yaml file (replace ${LINUX_ROOT_DATA_DIR} with ${ROOT_DATA_DIR})."$'\n'
    fi
    if [ "${OS_NAME}" = "Darwin" ]; then
        extra_msg="${extra_msg}- Since you are running on Mac, you have to update the docker-compose yaml file (replace ${LINUX_ROOT_DATA_DIR} with ${ROOT_DATA_DIR}).\n"
        extra_msg="${extra_msg}- Directory ${ROOT_DATA_DIR}/artifactory is created with wide permissions (777). SHOULD NOT be used like this in production!\n\tSee https://www.jfrog.com/confluence/display/RTF/Installing+with+Docker#InstallingwithDocker-ManagingDataPersistence"
    fi
    
    cat << END_NOTES2
$(echo -e ${extra_msg})
======================================

END_NOTES2
}

setOS
validateSudo
processOptions $*
cleanDataDir
createDirectories
copyFiles
setPermissions

showNotes
