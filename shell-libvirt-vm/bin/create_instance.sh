#!/bin/bash

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)
. ${SCRIPTS_DIR}/../lib/common.sh
. ${SCRIPTS_DIR}/../var/env.sh

# instance_name="test001"
# instance_vcpu=1
# instance_memory_k=2097152
# instance_disk="/var/lib/libvirt/images/test001.qcow2"
# net_name="mgmt-net"

template_name=""
instance_name=""
instance_vcpu=1
instance_memory_g=1
net_name="default"

pool_name="default"

while getopts "hvi:t:n:c:m:" arg
do
    case $arg in
        i)
            instance_name=$OPTARG
        ;;
        t)
            template_name=$OPTARG
        ;;
        n)
            net_name=$OPTARG
        ;;
        c)
            instance_vcpu=$OPTARG
        ;;
        m)
            instance_memory_g=$OPTARG
        ;;
        v)
            echo "Version 1.0"
            exit 0
        ;;
        h|?)
            echo "$0 <-i instance_name> <-t template_name> -n <net_name>"
            exit 0
        ;;
    esac
done

if [ -z "$template_name" ] || [ -z "$instance_name" ] || [ -z $net_name ]; then
    echo "$0 <-i instance_name> <-t template_name> -n <net_name>"
    exit 1
fi

instance_memory_k=$(($instance_memory_g * ${G_TO_K}))
instance_name="${INSTANCE_PREFIX}${instance_name}"

volume_clone $template_name $instance_name $pool_name
volume_path=$(get_volume_path $instance_name $pool_name)
instance_xml_file=$(create_instance_xml $instance_name $instance_vcpu $instance_memory_k $volume_path $net_name)
instance_define_by_xml $instance_xml_file
instance_start "$instance_name"
get_instance_info "$instance_name"

