#!/bin/bash

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)
. ${SCRIPTS_DIR}/../lib/common.sh
. ${SCRIPTS_DIR}/../var/env.sh


instance_name=""
pool_name="$POOL_NAME"

while getopts "hvn:" arg
do
    case $arg in
        n)
            instance_name=$OPTARG
        ;;
        v)
            echo "Version 1.0"
            exit 0
        ;;
        h|?)
            echo "$0 <-n instance_name>"
            exit 0
        ;;
    esac
done

if [ -z "$instance_name" ]; then
    echo "$0 <-n instance_name>"
    exit 1
fi

volumes=$(get_instance_disk $instance_name)
instance_destroy $instance_name
instance_undefine $instance_name

for vol in "$volumes"; do
    volume_delete $vol $pool_name
done
