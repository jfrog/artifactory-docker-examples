#!/bin/bash

# This file is for preparing all the needed files and directories on the host.
# These directories are mounted into the Docker containers.

SCRIPT_DIR=$(dirname $0)
DEFAULT_ROOT_DATA_DIR=/data
LINUX_ROOT_DATA_DIR=${DEFAULT_ROOT_DATA_DIR}
MAC_DEFAULT_ROOT_DATA_DIR=~/.artifactory

errorExit () {
    echo; echo "ERROR: $1"; echo
    exit 1
}

usage () {

    cat << END_USAGE

$0 - script for preparing the needed directories on the local host for mounting into the Artifactory Docker containers

Usage: $0 options
Supported options
-t   : (Required) Deployment type. 'pro', 'ha' or 'ha-shared-data'
       - pro            : Single Pro node
       - ha             : HA with two nodes
       - ha-shared-data : HA that uses a shared data mount
-d   : Custom root data directory (defaults to /data)
-c   : Clean local data directory. Delete the data directory on the host before creating the new ones
-f   : Force removal if -c is passed (do not prompt)
-h   : Show this usage

Examples
Prepare directories for Artifactory pro with default data directory
Start : sudo $0 -t pro -c

Prepare a default HA deployment directories
Start : sudo $0 -t ha -c

END_USAGE

    exit 1
}

setOS () {
    OS_TYPE=$(uname)
    if [[ ! $OS_TYPE =~ Darwin|Linux ]]; then
        errorExit "This script can run on Mac or Linux only!"
    fi

    # On Mac, set DEFAULT_ROOT_DATA_DIR to ~/.artifactory
    if [ "$OS_TYPE" == "Darwin" ]; then
        echo "On Mac. Setting DEFAULT_ROOT_DATA_DIR to $MAC_DEFAULT_ROOT_DATA_DIR"
        DEFAULT_ROOT_DATA_DIR=${MAC_DEFAULT_ROOT_DATA_DIR}
    fi
}

validateSudo () {
    if [ "$OS_TYPE" == "Linux" ] && [ $EUID -ne 0 ]; then
        errorExit "This script must be run as root or with sudo"
    fi
}

# Process command line options. See usage above for supported options
processOptions() {
    while getopts ":t:d:cfh" opt; do
        case $opt in
            t)  # Run type
                TYPE=$OPTARG
                if [[ ! "$TYPE" =~ ^(pro|ha|ha-shared-data)$ ]]; then
                    echo "ERROR: Deployment type $TYPE is not supported"
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
    if [ -z "$TYPE" ]; then
        echo "You must pass a deployment type (-t <pro|ha|ha-shared-data>)"
        usage
    fi

    # Set ROOT_DATA_DIR
    if [ -z "$ROOT_DATA_DIR" ]; then
        ROOT_DATA_DIR=${DEFAULT_ROOT_DATA_DIR}
    fi
}

cleanDataDir () {
    if [ "$CLEAN" == "true" ] && [ -d ${ROOT_DATA_DIR} ]; then
        local sure='n'

        if [ "$FORCE" == "true" ]; then
            sure='y'
        else
            read -p "Are you sure you want to remove existing ${ROOT_DATA_DIR} [y/n]: " sure
        fi
        if [ "$sure" == "y" ]; then
            echo "Removing old ${ROOT_DATA_DIR}"
            rm -rf ${ROOT_DATA_DIR}
        fi
    fi
}

createDirectories () {
    echo "Creating ${ROOT_DATA_DIR}"
    mkdir -p ${ROOT_DATA_DIR}/postgresql
    if [ "$TYPE" == "pro" ]; then
        mkdir -p ${ROOT_DATA_DIR}/artifactory/etc
    else
        mkdir -p ${ROOT_DATA_DIR}/artifactory/node{1,2}/etc
        if [ "$TYPE" == "ha-shared-data" ]; then
            mkdir -p ${ROOT_DATA_DIR}/artifactory/{ha,backup}
        fi
    fi
    mkdir -p ${ROOT_DATA_DIR}/nginx/{conf.d,log,ssl}
}

copyFiles () {
    echo "Copying needed files to directories"

    echo "Artifactory configuration files"
    if [ "$TYPE" == "pro" ]; then
        cp -f ${SCRIPT_DIR}/files/security/communication.key ${ROOT_DATA_DIR}/artifactory/etc
        cp -fr ${SCRIPT_DIR}/files/access ${ROOT_DATA_DIR}/artifactory/
    else
        cp -f ${SCRIPT_DIR}/files/security/communication.key ${ROOT_DATA_DIR}/artifactory/node1
        cp -fr ${SCRIPT_DIR}/files/access ${ROOT_DATA_DIR}/artifactory/node1/
        cp -f ${SCRIPT_DIR}/files/security/communication.key ${ROOT_DATA_DIR}/artifactory/node2
        cp -fr ${SCRIPT_DIR}/files/access ${ROOT_DATA_DIR}/artifactory/node2/

        # Copy the binarystore.xml which has configuration for no-shared storage
        if [ "$TYPE" == "ha" ]; then
            cp -f ${SCRIPT_DIR}/files/binarystore.xml ${ROOT_DATA_DIR}/artifactory/node1/etc
        fi
    fi

    echo "Nginx Artifactory configuration"
    cp -fr ${SCRIPT_DIR}/files/nginx/conf.d ${ROOT_DATA_DIR}/nginx/
}

showNotes () {
    cat << END_NOTES1

======================================
IMPORTANT
* Before starting, it is recommended to place the license file(s) (artifactory.lic) in the Artifactory etc directory
  - Artifactory pro:   ${ROOT_DATA_DIR}/artifactory/etc
  - Artifactory HA :   ${ROOT_DATA_DIR}/artifactory/node1/etc
                       ${ROOT_DATA_DIR}/artifactory/node2/etc
* The communication and access keys used in these examples SHOULD NOT be used for production!
END_NOTES1

    local extra_msg=""
    if [ "$DEFAULT_ROOT_DATA_DIR" != "$ROOT_DATA_DIR" ]; then
        extra_msg="* You changed the default root data directory to $ROOT_DATA_DIR, you have to update the docker-compose yaml file (replace $LINUX_ROOT_DATA_DIR with $ROOT_DATA_DIR)."$'\n'
    fi
    if [ "$OS_TYPE" == "Darwin" ]; then
        extra_msg="$extra_msg* Since you are running on Mac, you have to update the docker-compose yaml file (replace $LINUX_ROOT_DATA_DIR with $ROOT_DATA_DIR)."
    fi
    cat << END_NOTES2
$extra_msg
======================================

END_NOTES2
}

setOS
validateSudo
processOptions $*
cleanDataDir
createDirectories
copyFiles

showNotes
