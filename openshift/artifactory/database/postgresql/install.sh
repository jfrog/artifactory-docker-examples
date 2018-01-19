#!/bin/sh
print_help() {
    echo "Usage:"
    echo "  install.sh -o OPERATION"
    echo ""
    echo "Options:"
    echo "  -o, --operation: (create|replace|delete)"
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

oc $OPERATION -f postgresql-pvc.yaml
oc $OPERATION -f postgresql-deployment.yaml
oc $OPERATION -f postgresql-service.yaml
