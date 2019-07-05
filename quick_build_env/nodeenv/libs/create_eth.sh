# file_name: libs/create_eth.sh

function create_eth()
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

function create_eth0()
{
    vm_mount_dir=$1
    vm_net=$2
    create_eth  "${vm_mount_dir}/etc/sysconfig/network-scripts/ifcfg-eth0" eth0 $(echo $vm_net|awk -F "," '{for(i=1;i<=NF;i++){print $i}}')
}


function config_vm_eth()
{
    vm_mount_dir=$1
    vm_nets=$2
    echo "config vm nets: $vm_nets"
    echo $vm_nets | awk -F ";"  '{for(i=1;i<=NF;i++){print "eth"i-1" "$i}}' | while read eth_name ip_info; do 
        echo "config vm nic: $eth_name"
        create_eth  "${vm_mount_dir}/etc/sysconfig/network-scripts/ifcfg-${eth_name}" ${eth_name} $(echo $ip_info|awk -F "," '{for(i=1;i<=NF;i++){print $i}}')
        # create_eth  "ifcfg-${eth_name}" ${eth_name} $(echo $ip_info|awk -F "," '{for(i=1;i<=NF;i++){print $i}}')
    done
}

$1
# vim: tabstop=4 shiftwidth=4 softtabstop=4
