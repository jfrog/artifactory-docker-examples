#!/bin/sh
print_help() {
    echo "Usage:"
    echo "  run.sh -o OPERATION -p PARAMETERS_FILE [options]"
    echo ""
    echo "Options:"
    echo "  -o, --operation: (create|delete)"
    echo "  -p, --param-file: Path to the parameters file"
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

printenv | oc process postgresql-volumes-claim-template --ignore-unknown-parameters --param-file=- | oc $OPERATION -f -
printenv | oc process postgresql-template --ignore-unknown-parameters --param-file=- | oc $OPERATION -f -
printenv | oc process postgresql-service-template --ignore-unknown-parameters --param-file=- | oc $OPERATION -f -
