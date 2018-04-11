export XRAY_TO_VERSION=1.12.0
# Current Xray version can be fetched via curl XRAY_URL/api/v1/system/version


start() {
 scale $1 1
}

shutdown() {
 scale $1 0
}

scale() {
 oc scale dc $1 --replicas=$2
}


upgrade() {
 oc set triggers dc $1
 oc set triggers dc $1 --remove-all
 oc set triggers dc $1 --from-image=xray-$1:$2 --containers=$1
 oc set triggers dc $1
}


export DC="server persist analysis indexer event"

for i in $DC; do
 shutdown $i
done

sleep 30

for i in $DC; do
 upgrade $i $XRAY_TO_VERSION
 start $i
done
