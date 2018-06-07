#!/bin/sh
print_help() {
    echo "Usage:"
    echo "  process.sh -o OPERATION -p PARAMETERS_FILE [options]"
    echo ""
    echo "Options:"
    echo "  -o, --operation: (create|replace|delete)"
    echo "  -p, --param-file: Path to the parameters file"
}

COMMON_TEMPLATES=("artifactory-database-config-map-template" "artifactory-imagestream-template" "artifactory-primary-pvc-template" "artifactory-secondary-pvc-template" "artifactory-service-template")
SPECIFIC_TEMPLATES=("artifactory-binarystore-no-nfs-config-map-template" "artifactory-primary-deployment-template" "artifactory-secondary-deployment-template")

process_template() {
    printenv | oc process $1 --ignore-unknown-parameters --param-file=- | oc $OPERATION -f -
}

OPERATION=""
PARAMETERS_FILE=""

while [ "$1" != "" ]; do
    case $1 in
        -o | --operation )
            shift
            OPERATION=$1
            ;;
        -p | --param-file )
            shift
            PARAMETERS_FILE=$1
    esac
    shift
done

if [ "$OPERATION" == "" -o "$PARAMETERS_FILE" == "" ]; then
    print_help
    exit -1
fi

if [ ! -f $PARAMETERS_FILE ]; then
    echo "File $PARAMETERS_FILE not found"
    exit -2
fi

while IFS='' read -r line || [[ -n "$line" ]]; do
    export "$line"
done < "$PARAMETERS_FILE"

for TEMPLATE in "${COMMON_TEMPLATES[@]}"; do
    process_template $TEMPLATE
done

for TEMPLATE in "${SPECIFIC_TEMPLATES[@]}"; do
    process_template $TEMPLATE
done
