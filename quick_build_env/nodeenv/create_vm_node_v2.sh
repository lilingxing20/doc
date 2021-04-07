#!/bin/bash

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)

if [ ! -f "$1" ]; then
    tmp=($(ls $SCRIPTS_DIR/scene/*))
    echo -e "\nNeed node env file: ${tmp[@]#*.}\n"
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

# Set yum repo.
REPO_FILE=${REPO_FILE:-"${SCRIPTS_DIR}/repo/CentOS-7-reg-huawei.repo"}

# VM first boot script.
FIRST_BOOT_SCRIPT_DIR="${SCRIPTS_DIR}/custom_script"

ENV_NAME=$(basename $1)
TMP_DIR="${SCRIPTS_DIR}/run/${ENV_NAME}"
ETC_HOSTS_FILE="${TMP_DIR}/hosts"


# Check base image.
if [ ! -f $BASE_IMAGE ]; then
    echo "Please check: $BASE_IMAGE"
    exit 1
fi
# Check repo file.
[ -f $REPO_FILE ] || echo "Waring: not found $REPO_FILE"

# Init env dir
test -d $TMP_DIR || mkdir -p $TMP_DIR

# The env has been built
test -f $ETC_HOSTS_FILE && exit 0

echo -e "\n=> Make etc hosts file: $ETC_HOSTS_FILE"
net_type_arr=($(echo ${NODE_ARRAY} | awk '{print $7}' | awk -F ";" '{for(i=1;i<=NF;i++){print $i}}' | awk -F ',' '{print $1}'))
echo ${net_type_arr[*]}
net_num=${#net_type_arr[@]}
cat >$ETC_HOSTS_FILE <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF
for idx in $(seq "$NODE_NUM"); do
    host_name=$(echo ${NODE_ARRAY[$idx]} | awk '{print $2}')
    net_arr=($(echo ${NODE_ARRAY[$idx]} | awk '{print $7}' | awk -F ";" '{for(i=1;i<=NF;i++){print $i}}' |awk -F ',' '{print $1}'))
    echo ${net_arr[*]}
    for i in $(seq 0 "$(($net_num-1))"); do 
        if [[ "${net_arr[$i]}" =~ .*/.* ]]; then
            #[[ "${net_type_arr[$i]}" =~ control.* ]] && echo -e "${net_arr[$i]##*/}\t${host_name}\n${net_arr[$i]%%/*}\t${host_name}" >>$ETC_HOSTS_FILE
            [[ "${net_type_arr[$i]}" =~ control.* ]] && echo -e "${net_arr[$i]##*/}\t${host_name}" >>$ETC_HOSTS_FILE
            echo -e "${net_arr[$i]##*/}\t${host_name}-ipv6-${net_type_arr[$i]}" >>$ETC_HOSTS_FILE
            echo -e "${net_arr[$i]%%/*}\t${host_name}-${net_type_arr[$i]}" >>$ETC_HOSTS_FILE
        else
            [[ "${net_type_arr[$i]}" =~ control.* ]] && echo -e "${net_arr[$i]}\t${host_name}" >>$ETC_HOSTS_FILE
            echo -e "${net_arr[$i]}\t${host_name}-${net_type_arr[$i]}" >>$ETC_HOSTS_FILE
        fi
    done
done


echo -e "\n=> Get base image info."
base_image_size=$(get_vm_disk_size $BASE_IMAGE)
base_image_root_patition=$(get_root_partition $BASE_IMAGE)
echo "base_image_size: $base_image_size"
echo "base_image_root_patition: $base_image_root_patition"


# Create VM node
for idx in $(seq "$NODE_NUM"); do
    echo -e "\n=> Create VM node: $idx"
    echo ${NODE_ARRAY[$idx]} | while read  VM_NAME HOST_NAME CPU MEM VM_DISKS VM_NICS VM_NETS PASSWORD; do

        echo "Make vm($VM_NAME) boot disk file."
        vm_boot_disk=$VM_DISK_DIR/${VM_NAME}.qcow2
        #vm_boot_disk_size=$(echo "$VM_DISKS" | awk -F";" '{print $1}')
        vm_boot_disk_size=${VM_DISKS%%;*}
        check_vm_disk_size "$base_image_size" "$vm_boot_disk_size"
        make_vm_boot_disk "$vm_boot_disk" "$vm_boot_disk_size" "$BASE_IMAGE" "$base_image_root_patition"

        echo "Set vm firstboot script:"
        set_vm_firstboot_script "$vm_boot_disk" "$FIRST_BOOT_SCRIPT_DIR"

        echo "Set vm($VM_NAME) hostname($HOST_NAME)."
        set_vm_hostname "$vm_boot_disk" "$HOST_NAME"

        # set network eth* config file
        eth_cfg_dir="$TMP_DIR/${VM_NAME}/eth/"
        echo "Make vm network eth* config file."
        make_vm_eth_cfg "$eth_cfg_dir" "$VM_NETS"
        echo "Set vm network eth* config."
        set_vm_eth_cfg "$vm_boot_disk" "$eth_cfg_dir"
        
        # add repo
        #mkdir -pv ${vm_mount_dir}etc/yum.repos.d/bak
        #mv ${vm_mount_dir}etc/yum.repos.d/*.repo ${vm_mount_dir}etc/yum.repos.d/bak/
        #test -f ${REPO_FILE} && cp -v ${REPO_FILE} ${vm_mount_dir}etc/yum.repos.d/
        
        echo "Set vm etc hosts."
        set_vm_etc_hosts "$vm_boot_disk" "$ETC_HOSTS_FILE"

        echo "Set vm timezone: Asia/Shanghai."
        set_vm_time_zone "$vm_boot_disk" "Asia/Shanghai"

        echo "Set vm root password: ${PASSWORD:-$DEFAULT_PASSWORD}"
        set_vm_root_pwd "$vm_boot_disk" "${PASSWORD:-$DEFAULT_PASSWORD}"
        
        # authorized_keys
        #newvm_ssh_dir=${vm_mount_dir}root/.ssh/
        #test -d ${newvm_ssh_dir} || mkdir -m 700 ${newvm_ssh_dir}
        #test -f "$HOME/.ssh/id_rsa.pub" || ssh-keygen -f $HOME/.ssh/id_rsa -N ""
        #cat $HOME/.ssh/id_rsa.pub >> ${newvm_ssh_dir}/authorized_keys
        #chmod 600 ${newvm_ssh_dir}/authorized_keys
    
        echo "Make vm($VM_NAME) domain."
        make_vm_domain "$VM_NAME" "$CPU" "$MEM" "$vm_boot_disk" "$VM_NICS"

        echo "Attach volume:"
        attach_volumes "$VM_NAME" "$VM_DISK_DIR" "${VM_DISKS#*;}"

        sleep 5
    done
done

