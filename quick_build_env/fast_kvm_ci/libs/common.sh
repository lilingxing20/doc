## common function


function init_ssh_key() {
    ssh_dir=~/.ssh
    test -d ${ssh_dir} || mkdir -m 700 ${ssh_dir}
    test -f "${ssh_dir}/id_rsa.pub" || ssh-keygen -f ${ssh_dir}/id_rsa -N ""
    test -f "${ssh_dir}/authorized_keys" || touch "${ssh_dir}/authorized_keys"
    chmod 600 ${ssh_dir}/authorized_keys
}


function check_gen_ssh_key() {
    pub_key_file=${1:-"$HOME/.ssh/id_rsa.pub"}
    if [ -f "$pub_key_file" ]
    then
        echo "Current env ssh pub key is ${pub_key_file}"
    else
        echo "Warnning: Current env ssh key($pub_key_file) not exist"
        echo "Gen ssh key:"
        ssh-keygen -f ${pub_key_file%.*} -N ""
    fi
}


function get_os_release_id() {
    vm_disk=$1
    os_relase_id=$(virt-cat -a "${vm_disk}" /etc/os-release | grep "^ID=" | awk -F'"' '{print $2}')
    echo $os_relase_id
}


function get_vm_disk_size() {
    vm_disk=$1
    base_disk_size=$(qemu-img info "$vm_disk" | grep 'virtual size:' | awk '{print $3}' |tr -d G)
    echo $base_disk_size
}


function get_root_partition() {
    vm_disk=$1
    partitions=$(virt-alignment-scan -a "$vm_disk")
    root_partition=$(echo "$partitions" | tail -1 | awk '{print $1}')
    echo $root_partition
}


function check_vm_disk_size() {
    base_image_size=$1
    disk_size=$2
    if [[ $disk_size -lt $base_image_size ]];then
        echo "The newly created disk must be greater than or equal to the base image size(new disk size: $disk_size, base image size: $base_image_size)"
        exit 1
    fi
}


function create_qcow2_file() {
    vm_disk=$1
    disk_size=$2
    qemu-img create -f qcow2 ${vm_disk} ${disk_size}G
}


function make_vm_boot_disk() {
    vm_boot_disk=$1
    disk_size=$2
    base_image=$3
    base_image_root_patition=${4:-"/dev/sda2"}
    create_qcow2_file ${vm_boot_disk} ${disk_size}
    virt-resize --expand ${base_image_root_patition} ${base_image} ${vm_boot_disk} --quiet
}


function create_eth_cfg_file()
{
    eth_file=$1
    eth_name=$2
    ipaddr=$3
    gateway=$4
    dns1=$5
    dns2=$6
    ipv4addr=${ipaddr%%/*}
    ipv6addr=${ipaddr##*/}

    if [ -z "$eth_file" ] || [ -z "$eth_name" ]
    then
        return
    fi
    if [ "$ipaddr" == "dhcp" ]
    then
        cat >$eth_file <<EOF
TYPE=Ethernet
BOOTPROTO=dhcp
DEFROUTE=no
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=no
IPV6_DEFROUTE=no
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=$eth_name
DEVICE=$eth_name
ONBOOT=yes
EOF
    else
        cat >$eth_file <<EOF
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=no
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=no
IPV6_DEFROUTE=no
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=$eth_name
DEVICE=$eth_name
ONBOOT=yes
IPADDR=$ipv4addr
PREFIX=24
EOF
        if [ -n "$gateway" ]; then
            echo "GATEWAY=$gateway" >>$eth_file
            sed -i 's/DEFROUTE=no/DEFROUTE=yes/' $eth_file
        fi
        if [ -n "$dns1" ]; then
            echo "DNS1=$dns1" >>$eth_file
        fi
        if [ -n "$dns2" ]; then
            echo "DNS2=$dns2" >>$eth_file
        fi
        if [ -n "$ipv6addr" ] && [ "$ipv6addr" != "$ipv4addr" ]; then
            echo "IPV6ADDR=$ipv6addr/64" >>$eth_file
        fi
    fi
}


function make_vm_eth_cfg() {
    eth_cfg_dir=$1
    vm_nets=$2
    os_relase_id=$3
    # echo "Config vm nets: $vm_nets"
    [ -d $eth_cfg_dir ] || mkdir -p $eth_cfg_dir
    echo $vm_nets | awk -F ";"  '{for(i=1;i<=NF;i++){print i" "i-1" "$i}}' | while read idx idx_1 ip_info; do
        if [ "$os_relase_id" == "openEuler" ]; then
            eth_name="enp${idx}s0"
        else
            eth_name="eth${idx_1}"
        fi
        echo "  vm net: $eth_name"
        create_eth_cfg_file  "${eth_cfg_dir}/ifcfg-${eth_name}" ${eth_name} $(echo $ip_info|awk -F "," '{for(i=1;i<=NF;i++){print $i}}')
    done
}


function make_vm_domain() {
    vm_name=$1
    vm_cpu=$2
    vm_mem=$3
    vm_boot_disk=$4
    vm_nics=$5
    node_role=$6
    os_relase_id=$7
    cmd="virt-install --virt-type kvm --os-type=linux --name=${vm_name} --ram=${vm_mem} --vcpus=${vm_cpu} --import --disk path=${vm_boot_disk} --graphics vnc,listen=0.0.0.0,port=-1 --console pty,target_type=serial --noautoconsole"
    if [ "$os_relase_id" == "openEuler" ]; then
        cmd="$cmd --os-variant=openeuler20.03"
    else
        cmd="$cmd --os-variant=centos7.0"
    fi
    for vm_nic in $(echo $vm_nics | awk -F";" '{for(i=1;i<=NF;i++) print $i}')
    do
        [ -z "$vm_nic" ] && break
        net_name=$(echo "${vm_nic}" | awk -F"," '{print $1}')
        net_type=$(echo "${vm_nic}" | awk -F"," '{print $2}')
        if [ "bridge" == "$net_type" ]
        then
            cmd="$cmd --network bridge=${net_name},model=virtio"
        else
            cmd="$cmd --network network=${net_name},model=virtio"
        fi
    done
    if [ "$node_role" == "bm" ]
    then
        cmd="$cmd --os-type=linux --boot network,hd --pxe --force --autostart --wait=0"
    fi
    ${cmd}
}


function wait_vm_running() {
    vm_name=$1
    while true
    do
        vm_state=$(virsh domstate bm1 2>/dev/null)
        [ 'running' == "$vm_state" ] && break
        echo "Wait vm running, sleep 5s ..."
        sleep 5
    done
}


function make_vbmc_node() {
    vm_name=$1
    bm_port=$2
    wait_vm_running "$vm_name"
    which vbmc >/dev/null
    if [ "$?" == "0" ]; then
        vbmc add $vm_name --port $bm_port
        vbmc start $vm_name
    else
        echo "WARN: No vbmc node($vm_name) created!"
    fi
}


function vm_destroy() {
    vm_name=$1
    virsh destroy $vm_name
}


function vm_start() {
    vm_name=$1
    virsh start $vm_name
}


function attach_volume() {
    vm_name=$1
    disk_file=$2
    target=$3
    targetbus=${4-:"virtio"}
    virsh attach-disk "$vm_name" "$disk_file" "$target" --subdriver qcow2 --targetbus "$targetbus" --persistent
}


function attach_volumes() {
    vm_name=$1
    vm_disk_dir=$2
    disks_size=$3
    targetbus=${4:-"virtio"}

    disk_prefix="vd"
    [ "$targetbus" == "scsi" ] && disk_prefix="sd"
    target_dev_names=($(for i in {a..z};do echo ${disk_prefix}${i}; done))
    echo "$disks_size" | awk -F";" '{for(i=2;i<=NF;i++) print i-1" "$i}' | while read idx disk_size
    do
        [ -z "$disk_size" ] && break
        vm_vol_disk="${vm_disk_dir}/${vm_name}_vol_${idx}.qcow2"
        echo "  source: $vm_vol_disk, target: ${target_dev_names[$idx]}"
        create_qcow2_file "${vm_vol_disk}" "${disk_size}"
        attach_volume "$vm_name" "$vm_vol_disk" "${target_dev_names[$idx]}" "$targetbus"
    done
}


function set_vm_sysprep() {
    vm_boot_disk=$1
    vm_root_pwd=$2
    vm_hn_file=$3
    etc_hosts_file=$4
    eth_cfg_dir=$5
    firstboot_custom_script_dir=$6
    os_relase_id=$7
    sysprep_cmd="virt-sysprep -a ${vm_boot_disk} --selinux-relabel --quiet"
    sysprep_cmd="$sysprep_cmd --timezone Asia/Shanghai"
    [ -n "$vm_root_pwd" ] && sysprep_cmd="$sysprep_cmd --root-password password:${vm_root_pwd}"
    if [ "$os_relase_id" == "openEuler" ]; then
        sysprep_cmd="$sysprep_cmd --upload $vm_hn_file:/etc/hostname"
    else
	sysprep_cmd="$sysprep_cmd --hostname $(cat $vm_hn_file)"
    fi
    [ -f "$etc_hosts_file" ] && sysprep_cmd="$sysprep_cmd --upload $etc_hosts_file:/etc/hosts"
    # sysprep_cmd="$sysprep_cmd --ssh-inject root"
    for eth_file in $(ls $eth_cfg_dir)
    do
        sysprep_cmd="$sysprep_cmd --upload $eth_cfg_dir/$eth_file:/etc/sysconfig/network-scripts/$eth_file"
    done
    for script_file in $(ls $firstboot_custom_script_dir)
    do
        if [ "$os_relase_id" == "openEuler" ]; then
            sysprep_cmd="$sysprep_cmd --upload ${firstboot_custom_script_dir}/${script_file}:/usr/lib/virt-sysprep/scripts"
        else
            sysprep_cmd="$sysprep_cmd --firstboot ${firstboot_custom_script_dir}/${script_file}"
	fi
    done
    $sysprep_cmd
}

# vim: tabstop=4 shiftwidth=4 softtabstop=4
