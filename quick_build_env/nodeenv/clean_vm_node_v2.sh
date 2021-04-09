#!/bin/bash

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)

if [ ! -f "$1" ]; then
    tmp=($(ls $SCRIPTS_DIR/scene/*))
    echo -e "\nNeed node env file: ${tmp[@]#*.}\n"
    exit 1
fi

source $1


# VM create info list. from source $1.
NODE_NUM=$((${#NODE_ARRAY[@]}-1))

# VM virtual disk path.
VM_DISK_DIR=${VM_DISK_DIR:-"/var/lib/libvirt/images"}
pool_name=$(basename $VM_DISK_DIR)

ENV_NAME=$(basename $1)
ETC_HOSTS_FILE="${SCRIPTS_DIR}/run/${ENV_NAME}/hosts"
TMP_DIR="${SCRIPTS_DIR}/run/${ENV_NAME}"

for idx in $(seq "$NODE_NUM"); do
echo $idx
echo ${NODE_ARRAY[$idx]} | while read  VM_NAME OTHER; do
    virsh list --all | grep $VM_NAME && virsh destroy $VM_NAME
    virsh list --all | grep $VM_NAME && virsh undefine $VM_NAME
    tmp_vm_dir="$TMP_DIR/${VM_NAME}"
    tmp_vm_eth_dir="${tmp_vm_dir}/eth"
    test -d $tmp_vm_eth_dir && rm -rfv $tmp_vm_eth_dir
    test -d $tmp_vm_dir && rmdir -v $tmp_vm_dir
    vm_boot_disk=$VM_DISK_DIR/${VM_NAME}.qcow2
    virsh vol-list --pool "$pool_name" | grep $VM_NAME | awk '{print $1}' | while read vol
    do
        virsh vol-delete --pool "$pool_name" "$vol"
    done
    test -f $vm_boot_disk && rm -fv $vm_boot_disk
done
done

test -f $ETC_HOSTS_FILE && rm -fv $ETC_HOSTS_FILE
test -d $TMP_DIR && rmdir -v $TMP_DIR

# vim: tabstop=4 shiftwidth=4 softtabstop=4
