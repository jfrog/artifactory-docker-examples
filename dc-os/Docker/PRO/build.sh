#!/usr/bin/env bash

SCRIPT_DIR=$(PWD)

echo $SCRIPT_DIR
mkdir files

echo "adding configuration file"
cp -Rf $SCRIPT_DIR/../../../files/* files/

docker build --rm -t $1 .
