#!/bin/sh
print_help() {
    echo "Usage:"
    echo "  install.sh -o OPERATION"
    echo ""
    echo "Options:"
    echo "  -o, --operation: (create|replace|delete)"
}

COMMON_TEMPLATES=("../artifactory-ha-common/config/database-config-map.yaml" "../artifactory-ha-common/secrets/artifactory-licenses-secret.yaml" "../artifactory-ha-common/secrets/artifactory-master-key-secret.yaml" "../artifactory-ha-common/artifactory-imagestream.yaml" "../artifactory-ha-common/artifactory-primary-pvc.yaml" "../artifactory-ha-common/artifactory-secondary-pvc.yaml" "../artifactory-ha-common/artifactory-service.yaml")
SPECIFIC_TEMPLATES=("artifactory-primary-deployment.yaml" "artifactory-secondary-deployment.yaml" "config/binarystore-config-map.yaml")

install_template() {
    oc $OPERATION -f $1
}

OPERATION=""

while [ "$1" != "" ]; do
    case $1 in
        -o | --operation )
            shift
            OPERATION=$1
    esac
    shift
done

if [ "$OPERATION" == "" ]; then
    print_help
    exit -1
fi

for TEMPLATE in "${COMMON_TEMPLATES[@]}"; do
    install_template $TEMPLATE
done

for TEMPLATE in "${SPECIFIC_TEMPLATES[@]}"; do
    install_template $TEMPLATE
done
