#!/bin/bash

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)
start_time="$(date -u +%s)"

if [ ! -f "$1" ]; then
    tmp=($(ls $SCRIPTS_DIR/scene/*))
    echo -e "\nNeed node env example file: ${tmp[@]}\n"
    exit 1
fi

source $1
source ${SCRIPTS_DIR}/libs/common.sh >/dev/null

if [ -z "$NODE_ARRAY" ]; then
    echo -e "\nThe NODE_ARRAY is null, please check file: $1\n"
    exit 1
fi

# VM create info list. from source $1.
NODE_NUM=$((${#NODE_ARRAY[@]}-1))

# VM virtual disk path.
VM_DISK_DIR=${VM_DISK_DIR:-"/var/lib/libvirt/images"}
echo "The VM virtual disk path: $VM_DISK_DIR"

# VM first boot script.
FIRST_BOOT_CUSTOM_SCRIPT_DIR="${SCRIPTS_DIR}/custom_script"
FIRST_BOOT_DEPLOY_SCRIPT_DIR="${SCRIPTS_DIR}/deploy_script"

# Upload file to vm /opt
UPLOAD_FILE_DIR="${SCRIPTS_DIR}/upload_file"

ENV_NAME=$(basename $1)
TMP_DIR="${SCRIPTS_DIR}/run/${ENV_NAME}"
ETC_HOSTS_FILE="${TMP_DIR}/hosts"


# Check VM_DISK_DIR
if [ ! -d $VM_DISK_DIR ]; then
    echo "ERR: Please create vm disk dir: mkdir -p $VM_DISK_DIR"
    exit 1
fi

# Check base image.
if [ ! -f $BASE_IMAGE ]; then
    echo "ERR: Please check: $BASE_IMAGE"
    exit 1
fi

# Check kvm env.
which virt-install >/dev/null
if [ "$?" != "0" ]; then
    echo "ERR: Please install the kvm environment: $SCRIPTS_DIR/install_kvm_env.sh"
    exit 1
fi
which vbmc >/dev/null
if [ "$?" != "0" ]; then
    echo "WARN: Please install the vbmc environment: $SCRIPTS_DIR/install_vbmc_env.sh"
    sleep 5
fi


# Init env dir
test -d $TMP_DIR || mkdir -p $TMP_DIR

# Init ssh key
#init_ssh_key

echo -e "\n=> Make etc hosts file: $ETC_HOSTS_FILE"
net_type_arr=($(echo ${NODE_ARRAY} | awk '{print $7}' | awk -F ";" '{for(i=1;i<=NF;i++){print $i}}' | awk -F ',' '{print $1}'))
echo ${net_type_arr[*]}
net_num=${#net_type_arr[@]}
cat >$ETC_HOSTS_FILE <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF
# for idx in $(seq "$NODE_NUM"); do
#     host_name=$(echo ${NODE_ARRAY[$idx]} | awk '{print $2}')
#     net_arr=($(echo ${NODE_ARRAY[$idx]} | awk '{print $7}' | awk -F ";" '{for(i=1;i<=NF;i++){print $i}}' |awk -F ',' '{print $1}'))
#     node_pwd=$(echo ${NODE_ARRAY[$idx]} | awk '{print $8}')
#     node_role=$(echo ${NODE_ARRAY[$idx]} | awk '{print $9}')
#     echo ${net_arr[*]}
#     for i in $(seq 0 "$(($net_num-1))"); do 
#         if [[ "${net_arr[$i]}" =~ .*/.* ]]; then
#             #[[ "${net_type_arr[$i]}" =~ control.* ]] && echo -e "${net_arr[$i]##*/}\t${host_name}\n${net_arr[$i]%%/*}\t${host_name}" >>$ETC_HOSTS_FILE
#             if [[ "${net_type_arr[$i]}" =~ control.* ]]
#             then
#                 echo -e "${net_arr[$i]##*/}\t${host_name}" >>$ETC_HOSTS_FILE
#             fi
#             echo -e "${net_arr[$i]##*/}\t${host_name}-ipv6-${net_type_arr[$i]}" >>$ETC_HOSTS_FILE
#             echo -e "${net_arr[$i]%%/*}\t${host_name}-${net_type_arr[$i]}" >>$ETC_HOSTS_FILE
#         else
#             if [[ "${net_type_arr[$i]}" =~ control.* ]]
#             then
#                 echo -e "${net_arr[$i]}\t${host_name}" >>$ETC_HOSTS_FILE
#             fi
#             echo -e "${net_arr[$i]}\t${host_name}-${net_type_arr[$i]}" >>$ETC_HOSTS_FILE
#         fi
#     done
# done


echo -e "\n=> Get base image info."
os_release_id=${IMAGE_OS_RELEASE_ID:-$(get_os_release_id $BASE_IMAGE)}
base_image_size=$(get_vm_disk_size $BASE_IMAGE)
base_image_root_patition=$(get_root_partition $BASE_IMAGE)
echo "base_image_os_release_id: $os_release_id"
echo "base_image_size: $base_image_size"
echo "base_image_root_patition: $base_image_root_patition"

# Create VM node
for idx in $(seq "$NODE_NUM"); do
    echo -e "\n=> Create VM node: $idx"
    echo ${NODE_ARRAY[$idx]} | while read  VM_NAME HOST_NAME CPU MEM VM_DISKS VM_NICS VM_NETS PASSWORD ROLE; do

        virsh list --all | grep $VM_NAME && continue

        vm_boot_disk=$VM_DISK_DIR/${VM_NAME}.qcow2
        vm_boot_disk_size=$(echo "$VM_DISKS" | awk -F";" '{print $1}')
        if [ $ROLE == 'bm' ]
        then
            echo "Make vm($VM_NAME) boot disk file"
            create_qcow2_file "$vm_boot_disk" "$vm_boot_disk_size"

            echo "Make vm($VM_NAME) domain."
            make_vm_domain "$VM_NAME" "$CPU" "$MEM" "$vm_boot_disk" "$VM_NICS" "$ROLE"

            echo "Make bm($VM_NAME) node"
            make_vbmc_node "$VM_NAME" "$HOST_NAME"

        else
            echo "Make vm($VM_NAME) boot disk file"
            check_vm_disk_size "$base_image_size" "$vm_boot_disk_size"
            make_vm_boot_disk "$vm_boot_disk" "$vm_boot_disk_size" "$BASE_IMAGE" "$base_image_root_patition"

            echo "Make vm($VM_NAME) network eth* config file"
            eth_cfg_dir="$TMP_DIR/${VM_NAME}/eth/"
            make_vm_eth_cfg "$eth_cfg_dir" "$VM_NETS" "$os_release_id"

            echo "Set vm($VM_NAME) sysprep"
            hn_file="${TMP_DIR}/${VM_NAME}/hostname"
            echo "$HOST_NAME" >$hn_file
            set_vm_sysprep "$vm_boot_disk" "${PASSWORD:-$DEFAULT_PASSWORD}" "$hn_file" "$ETC_HOSTS_FILE" "$eth_cfg_dir" "$FIRST_BOOT_CUSTOM_SCRIPT_DIR" "$os_release_id"

            echo "Make vm($VM_NAME) domain."
            make_vm_domain "$VM_NAME" "$CPU" "$MEM" "$vm_boot_disk" "$VM_NICS" "$ROLE" "$os_release_id"

            echo "Attach volume:"
            attach_volumes "$VM_NAME" "$VM_DISK_DIR" "$VM_DISKS" "$VOLUME_TARGETBUS"
        fi

        sleep 5
    done
done

end_time="$(date -u +%s)"
echo "Time elapsed $(($end_time-$start_time)) second"

# vim: tabstop=4 shiftwidth=4 softtabstop=4
