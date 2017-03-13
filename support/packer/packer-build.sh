#!/bin/bash

VERSION=$1
TYPE=$2
PROVIDER=$3

PACKER_PATH=$(pwd)/support/packer

cd $PACKER_PATH

# Azure instances needs to be deprovisioned at the end of the build process
if [ $PROVIDER == "azure" ]; then
    echo "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync" >> $PACKER_PATH/update-script-$TYPE.sh
fi

packer build -var "version=$VERSION" "$PACKER_PATH/packer-$PROVIDER-$TYPE.json"
