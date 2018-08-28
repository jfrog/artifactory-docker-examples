#!/bin/bash
if [ $# -lt 2 ]
        then
                echo "Usage: ./xray-wrapper.sh USER PARAMETERS_FILE"
                exit 1
fi

export USER=$1
export PARAMETERS_FILE=$2

if [ ! -f $PARAMETERS_FILE ]; then
    echo "File $PARAMETERS_FILE not found"
    exit -2
fi

processTemplates() {
 printenv | oc process -f $1 --ignore-unknown-parameters --param-file=- | oc create -f -
}

export PERSISTENT_VOLUME_CLAIMS="xray-data-pvc.yaml xray-postgres/xray-postgres-pvc.yaml xray-mongodb/xray-mongodb-pvc.yaml xray-rabbitmq/xray-rabbitmq-pvc.yaml"

export CONFIG_MAPS="xray-mongodb/xray-mongodb-setup-configmap.yaml xray-rabbitmq/xray-rabbitmq-configmap.yaml xray-setup-configmap.yaml"

export IMAGE_STREAMS="xray-imagestream.yaml"

export THIRDPARTY_MICROSERVICES="xray-postgres/xray-postgres.yaml xray-mongodb/xray-mongodb.yaml xray-rabbitmq/xray-rabbitmq.yaml"

export XRAY_MICROSERVICES="xray-indexer.yaml xray-analysis.yaml xray-persist.yaml xray-server.yaml"

export PROCESS_TEMPLATES="$CONFIG_MAPS $PERSISTENT_VOLUME_CLAIMS $IMAGE_STREAMS $THIRDPARTY_MICROSERVICES"

while IFS='' read -r line || [[ -n "$line" ]]; do
    export "$line"
done < "$PARAMETERS_FILE"


oc login -u $USER
oc project $NAMESPACE

for i in $PROCESS_TEMPLATES; do
  processTemplates $i
done

sleep 100

for i in $XRAY_MICROSERVICES; do
 processTemplates $i
done
