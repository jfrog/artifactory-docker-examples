#!/bin/bash
print_help() {
    echo "Usage:"
    echo "  rolling-upgrade.sh -p PARAMETERS_FILE"
    echo ""
    echo "Options:"
    echo "  -p, --param-file: Path to the parameters file"
}

get_replicas_count() {
    local REPLICAS=$(oc get dc $1 -n $NAMESPACE -o yaml | grep -w availableReplicas: | sed -n 's/.*availableReplicas: \([0-9]*\)/\1/p')
    echo "$REPLICAS"
}

shutdown() {
    echo "Shuting down $1"
    oc scale dc $1 -n $NAMESPACE --replicas=0

    echo "Waiting for $1 to be down"
    while [ true ]; do
        local REPLICAS=$(get_replicas_count $1)
        if [ $REPLICAS == 0 ]; then
            echo "$1 is down"
            return 0
        else
            echo "."
            sleep 10
        fi
    done

}

deploy() {
    echo "Deploying $1"
    oc scale dc $1 -n $NAMESPACE --replicas=1
    echo "Waiting for $1 to be up"
    while [ true ]; do
        local REPLICAS=$(get_replicas_count $1)
        if [ $REPLICAS == 1 ]; then
            echo "$1 is up"
            return 0
        else
            echo "."
            sleep 10
        fi
    done
}

PARAMETERS_FILE=""

while [ "$1" != "" ]; do
    case $1 in
        -p | --param-file )
            shift
            PARAMETERS_FILE=$1
    esac
    shift
done

if [ "$PARAMETERS_FILE" == "" ]; then
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

# Update image stream
echo "Upgrading image stream"
printenv | oc process artifactory-imagestream-template --ignore-unknown-parameters --param-file=- | oc replace -f -

# Update primary node
shutdown "$NAME-primary"
echo "Upgrading $NAME-primary"
printenv | oc process artifactory-nfs-primary-deployment-template --ignore-unknown-parameters --param-file=- | oc replace -f -
deploy "$NAME-primary"

# Update secondary node
shutdown "$NAME-secondary"
echo "Upgrading $NAME-secondary"
printenv | oc process artifactory-nfs-secondary-deployment-template --ignore-unknown-parameters --param-file=- | oc replace -f -
deploy "$NAME-secondary"

echo "$NAME upgraded successfully"
