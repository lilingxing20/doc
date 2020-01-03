#!/bin/bash
# set -x 
export LANG=en_US.UTF-8

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)

G_TO_M=1024
G_TO_K=1048576
G_TO_B=1073741824


## create volume xml, return pathfile
create_volume_xml()
{
    template_name=$1
    template_size_b=$2
    bash ${SCRIPTS_DIR}/../template/volume.xml.sh $template_name $template_size_b
}


## create instance xml, return pathfile
create_instance_xml()
{
    instance_name=$1
    instance_vcpu=$2
    instance_memory_k=$3
    instance_disk=$4
    net_name=$5
    bash ${SCRIPTS_DIR}/../template/instance.xml.sh $instance_name $instance_vcpu $instance_memory_k $instance_disk $net_name
}


###########################################################
#                      qemu-img                           #
###########################################################

## get image size
get_image_size_b()
{
    image_file=$1
    image_virtual_size_b=$(qemu-img info $image_file | awk '/^virtual*/{print $4}'| tr -d '(')
    echo $image_virtual_size_b
}


###########################################################
#                  vrish help volume                      #
###########################################################

## upload image to volume
image_upload_to_volume()
{
    vol_name=$1
    image_file=$2
    pool_name=$3
    virsh vol-upload $vol_name $image_file --pool $pool_name
}


## create volume
volume_create_by_xml()
{
    vol_xml_file=$1
    pool_name=$2
    ret=$(virsh vol-create $pool_name $vol_xml_file 2>&1)
    if [[ "$?" == "0" ]]; then
        rm -f $vol_xml_file
        echo "INFO:$LINENO: The volume ($(echo $ret | awk '{print $2}')) has created."
    else
        if [[ "$(echo $ret | grep -c 'exists already')" != "0" ]]; then
            rm -f $vol_xml_file
            echo "WARING:$LINENO: $(echo $ret | awk -F':' '{print $NF}')"
        else
            echo "ERROR:$LINENO: $ret"
        fi
    fi
}

## clone volume
volume_clone()
{
    template_name=$1
    volume_name=$2
    pool_name=$3
    ret=$(virsh vol-clone "$template_name" "$volume_name" --pool "$pool_name" 2>&1)
    if [[ "$?" == "0" ]]; then
        rm -f $vol_xml_file
        echo "INFO:$LINENO: $ret"
    else
        if [[ "$(echo $ret | grep -c 'already in use')" != "0" ]]; then
            echo "ERROR:$LINENO: $(echo $ret|awk -F':' '{print $NF}')"
        else
            echo "ERROR:$LINENO: $ret"
        fi
    fi
}


## delete a vol
volume_delete()
{
    volume_name=$1
    pool_name=$2
    virsh vol-delete "$volume_name" --pool "$pool_name"
}


## get volume info
get_volume_info()
{
    volume_name=$1
    pool_name=$2
    virsh vol-info "$volume_name" --pool "$pool_name"
}


## get volume path
get_volume_path()
{
    volume_name=$1
    pool_name=$2
    virsh vol-path "$volume_name" --pool "$pool_name"
}


## get volume key
get_volume_key()
{
    volume_name=$1
    pool_name=$2
    virsh vol-key "$volume_name" --pool "$pool_name"
}



###########################################################
#                  virsh help domin                       #
###########################################################

## create instance
instance_create_by_xml()
{
    instance_xml_file=$1
    ret=$(virsh create "$instance_xml_file" 2>&1)
    if [[ "$?" == "0" ]]; then
        rm -f $instance_xml_file
    fi
    echo "$ret"
}


## define instance
instance_define_by_xml()
{
    instance_xml_file=$1
    ret=$(virsh define "$instance_xml_file" 2>&1)
    if [[ "$?" == "0" ]]; then
        rm -f $instance_xml_file
        echo "INFO:$LINENO: $ret"
    else
        if [[ "$(echo $ret | grep -c 'already exists')" != "0" ]]; then
            rm -f $instance_xml_file
            echo "WARING:$LINENO: $(echo $ret | awk -F':' '{print $NF}')"
        else
            echo "ERROR:$LINENO: $ret"
        fi
    fi
}


## instance start
instance_start()
{
    instance_name=$1
    ret=$(virsh start "$instance_name" 2>&1)
    if [[ "$?" == "0" ]]; then
        echo "INFO:$LINENO: The instance ($instance_name) is starting."
    else
        if [[ "$(echo $ret | grep -c 'already active')" != "0" ]]; then
            echo "WARING:$LINENO: Instance ($instance_name) already active."
        else
            echo "ERROR:$LINENO: $ret"
            exit 1
        fi
    fi
}


## instance destroy
instance_destroy()
{
    instance_name=$1
    ret=$(virsh destroy "$instance_name" 2>&1)
    if [[ "$?" == "0" ]]; then
        echo "INFO:$LINENO: $ret"
    else
        if [[ "$(echo $ret | grep -c 'not running')" != "0" ]]; then
            echo "WARING:$LINENO: Instance ($instance_name) not running."
        else
            echo "ERROR:$LINENO: $ret"
            exit 1
        fi
    fi
}


## instance undefine
instance_undefine()
{
    instance_name=$1
    ret=$(virsh undefine "$instance_name" 2>&1)
    if [[ "$?" == "0" ]]; then
        echo "INFO:$LINENO: $ret"
    else
        if [[ "$(echo $ret | grep -c 'Domain not found')" != "0" ]]; then
            echo "WARING:$LINENO: Instance ($instance_name) not found."
        else
            echo "ERROR:$LINENO: $ret"
            exit 1
        fi
    fi
}


## get instance info
get_instance_info()
{
    instance_name=$1
    virsh dominfo "$instance_name"
}


## get instance info
get_instance_disk()
{
    instance_name=$1
    ret=$(virsh domblklist "$instance_name" 2>&1)
    if [[ "$?" == "0" ]]; then
        echo "$ret" | sed 1,2d | awk '{print $2}'
    else
        echo ""
    fi
}


