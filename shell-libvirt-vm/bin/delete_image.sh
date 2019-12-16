#!/bin/bash

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)
. ${SCRIPTS_DIR}/../lib/common.sh
. ${SCRIPTS_DIR}/../var/env.sh


template_name=""
pool_name="$POOL_NAME"

while getopts "hvn:" arg
do
    case $arg in
        n)
            template_name=$OPTARG
        ;;
        v)
            echo "Version 1.0"
            exit 0
        ;;
        h|?)
            echo "$0 <-n template_name>"
            exit 0
        ;;
    esac
done

if [ -z "$template_name" ]; then
    echo "$0 <-n template_name>"
    exit 1
fi

volume_delete "$template_name" --pool ${pool_name}
