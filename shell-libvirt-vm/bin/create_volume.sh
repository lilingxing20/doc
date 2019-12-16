#!/bin/bash

set +x

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)
. ${SCRIPTS_DIR}/../lib/common.sh
. ${SCRIPTS_DIR}/../var/env.sh


volume_name=""
volume_size_g=""
pool_name="default"

while getopts "hvn:s:" arg
do
    case $arg in
        n)
            volume_name=$OPTARG
        ;;
        s)
            volume_size_g=$OPTARG
        ;;
        v)
            echo "Version 1.0"
            exit 0
        ;;
        h|?)
            echo "$0 <-n volume_name> <-s volume_size (GB)>"
            exit 0
        ;;
    esac
done

if [ -z "$volume_name" ] || [ -z "$volume_size_g" ]; then
    echo "$0 <-n volume_name> <-s volume_size (GB)>"
    exit 1
fi

volume_name="${VOLUME_PREFIX}${volume_name}"

volume_size_b=$(($volume_size_g * $G_TO_B))
vol_xml_file=$(create_volume_xml $volume_name $volume_size_b)
volume_create_by_xml $vol_xml_file $pool_name
get_volume_info $volume_name $pool_name

