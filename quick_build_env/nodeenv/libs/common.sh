## common function

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

function set_vm_selinux_relabel() {
    vm_boot_disk=$1
    virt-sysprep -a ${vm_boot_disk} --selinux-relabel --quiet
}

function set_vm_hostname() {
    vm_boot_disk=$1
    vm_host_name=$2
    virt-sysprep -a ${vm_boot_disk} --selinux-relabel --hostname ${vm_host_name} --quiet
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

    if [ -z "$eth_file" ] || \
            [ -z "$eth_name" ] || \
            [ -z "$ipaddr" ] || \
            [ -z "$ipv4addr" ]; then
        exit
    fi

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
}

function make_vm_eth_cfg() {
    eth_cfg_dir=$1
    vm_nets=$2
    # echo "Config vm nets: $vm_nets"
    [ -d $eth_cfg_dir ] || mkdir -p $eth_cfg_dir
    echo $vm_nets | awk -F ";"  '{for(i=1;i<=NF;i++){print "eth"i-1" "$i}}' | while read eth_name ip_info; do 
        echo "  vm net: $eth_name"
        create_eth_cfg_file  "${eth_cfg_dir}/ifcfg-${eth_name}" ${eth_name} $(echo $ip_info|awk -F "," '{for(i=1;i<=NF;i++){print $i}}')
    done
}

function set_vm_eth_cfg() {
    vm_boot_disk=$1
    eth_cfg_dir=$2
    for eth_file in $(ls $eth_cfg_dir)
    do
      virt-sysprep -a ${vm_boot_disk} --selinux-relabel --upload $eth_cfg_dir/$eth_file:/etc/sysconfig/network-scripts/$eth_file --quiet
    done
}

function set_vm_etc_hosts() {
    vm_boot_disk=$1
    etc_hosts_file=$2
    if [ -f "$etc_hosts_file" ];then
        virt-sysprep -a ${vm_boot_disk} --selinux-relabel --upload $etc_hosts_file:/etc/hosts --quiet
    fi
}

function set_vm_time_zone() {
    vm_boot_disk=$1
    time_zone=${2:-"Asia/Shanghai"}
    virt-sysprep -a ${vm_boot_disk} --selinux-relabel --timezone ${time_zone} --quiet
}

function set_vm_root_pwd() {
    vm_boot_disk=$1
    vm_root_pwd=$2
    if [ -n "$vm_root_pwd" ];then
        virt-sysprep -a ${vm_boot_disk} --selinux-relabel --root-password password:${vm_root_pwd} --quiet
    fi
}

function set_vm_root_authorized_keys() {
    vm_boot_disk=$1
    pub_key_file=$2
    if [ -f "$pub_key_file" ];then
        virt-sysprep -a ${vm_boot_disk} --selinux-relabel --ssh-inject root:file:${vm_boot_disk} --quiet
    else
        virt-sysprep -a ${vm_boot_disk} --selinux-relabel --ssh-inject root --quiet
    fi
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

function set_vm_firstboot_script() {
    vm_boot_disk=$1
    firstboot_script_dir=$2
    for script_file in $(ls $firstboot_script_dir)
    do
        virt-sysprep -a ${vm_boot_disk} --selinux-relabel --firstboot "${firstboot_script_dir}/${script_file}" --quiet
    done
}

function set_vm_ssh_cfg() {
    vm_boot_disk=$1
    virt-sysprep -a ${vm_boot_disk} --selinux-relabel --ssh-inject root --edit '/etc/ssh/sshd_config:s/GSS/#GSS/' --edit '/etc/ssh/sshd_config:s/#UseDNS yes/UseDNS no/' --quiet
}


function make_vm_domain() {
    vm_name=$1
    vm_cpu=$2
    vm_mem=$3
    vm_boot_disk=$4
    vm_nics=$5
    cmd="virt-install --virt-type kvm --os-type=linux --os-variant=centos7.0 --name=${vm_name} --ram=${vm_mem} --vcpus=${vm_cpu} --import --disk path=${vm_boot_disk} --graphics vnc,listen=0.0.0.0,port=-1 --console pty,target_type=serial --noautoconsole"
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
    ${cmd}
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
    virsh attach-disk "$vm_name" "$disk_file" "$target" --subdriver qcow2 --targetbus virtio --persistent
}

function attach_volumes() {
    vm_name=$1
    vm_disk_dir=$2
    disks_size=$3
    target_dev_names=($(for i in {a..z};do echo vd$i; done))
    echo "$disks_size" | awk -F";" '{for(i=2;i<=NF;i++) print i-1" "$i}' | while read idx disk_size
    do
        [ -z "$disk_size" ] && break
        vm_vol_disk="${vm_disk_dir}/${vm_name}_vol_${idx}.qcow2"
        echo "  source: $vm_vol_disk, target: ${target_dev_names[$idx]}"
        create_qcow2_file "${vm_vol_disk}" "${disk_size}"
        attach_volume "$vm_name" "$vm_vol_disk" ${target_dev_names[$idx]}
    done
}

function set_vm_sysprep() {
    vm_boot_disk=$1
    vm_root_pwd=$2
    vm_host_name=$3
    etc_hosts_file=$4
    eth_cfg_dir=$5
    firstboot_script_dir=$6
    sysprep_cmd="virt-sysprep -a ${vm_boot_disk} --selinux-relabel --quiet"
    sysprep_cmd="$sysprep_cmd --timezone Asia/Shanghai"
    [ -n "$vm_root_pwd" ] && sysprep_cmd="$sysprep_cmd --root-password password:${vm_root_pwd}"
    [ -n "$vm_host_name" ] && sysprep_cmd="$sysprep_cmd --hostname $vm_host_name"
    [ -f "$etc_hosts_file" ] && sysprep_cmd="$sysprep_cmd --upload $etc_hosts_file:/etc/hosts"
    sysprep_cmd="$sysprep_cmd --ssh-inject root"
    for script_file in $(ls $FIRST_BOOT_SCRIPT_DIR)
    do
        sysprep_cmd="$sysprep_cmd --firstboot ${FIRST_BOOT_SCRIPT_DIR}/${script_file}"
    done
    for eth_file in $(ls $eth_cfg_dir)
    do
        sysprep_cmd="$sysprep_cmd --upload $eth_cfg_dir/$eth_file:/etc/sysconfig/network-scripts/$eth_file"
    done
    $sysprep_cmd
}

# vim: tabstop=4 shiftwidth=4 softtabstop=4
