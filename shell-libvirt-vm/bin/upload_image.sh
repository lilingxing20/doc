#!/bin/bash

set +x

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)
. ${SCRIPTS_DIR}/../lib/common.sh
. ${SCRIPTS_DIR}/../var/env.sh


image_file=""
template_name=""
pool_name="default"

while getopts "hvi:n:" arg
do
    case $arg in
        i)
            image_file=$OPTARG
        ;;
        n)
            template_name=$OPTARG
        ;;
        v)
            echo "Version 1.0"
            exit 0
        ;;
        h|?)
            echo "$0 <-i image_file> <-n template_name>"
            exit 0
        ;;
    esac
done

if [ -z "$image_file" ]; then
    echo "$0 <-i image_file> <-n template_name>"
    exit 1
fi

[ -z "$template_name" ] && template_name=$(basename $image_file)

template_name="${IMAGE_PREFIX}${template_name}"
echo $template_name, $image_file

template_size_b=$(get_image_size_b $image_file)
vol_xml_file=$(create_volume_xml $template_name $template_size_b)
volume_create_by_xml $vol_xml_file $pool_name
image_upload_to_volume $template_name $image_file $pool_name
get_volume_info $template_name $pool_name

