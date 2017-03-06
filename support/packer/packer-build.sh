#!/bin/bash

VERSION=$1
TYPE=$2
PROVIDER=$3

PACKER_PATH=$(pwd)/support/packer

cd $PACKER_PATH

packer build -var "version=$VERSION" "$PACKER_PATH/packer-$PROVIDER-$TYPE.json"
