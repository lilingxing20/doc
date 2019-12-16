#!/bin/bash

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)
. ${SCRIPTS_DIR}/../lib/common.sh
. ${SCRIPTS_DIR}/../var/env.sh


volume_name=""
pool_name="$POOL_NAME"

while getopts "hvn:" arg
do
    case $arg in
        n)
            volume_name=$OPTARG
        ;;
        v)
            echo "Version 1.0"
            exit 0
        ;;
        h|?)
            echo "$0 <-n volume_name>"
            exit 0
        ;;
    esac
done

if [ -z "$volume_name" ]; then
    echo "$0 <-n volume_name>"
    exit 1
fi

volume_delete "$volume_name" --pool ${pool_name}
