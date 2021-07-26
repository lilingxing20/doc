#!/bin/bash
## by lixx
# 2021-04-08
#

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)

eth_name=$1
br_name=$2

if [ -z "$eth_name" ] || [ -z "$br_name" ]
then
    echo "$0 <eth_name> <br_name>"
    exit 0
fi

rpm -q bridge-utils >/dev/null
if [ $? != 0 ]
then
    echo "Please install bridge-utils first!"
    exit 1
fi
rpm -q net-tools >/dev/null
if [ $? != 0 ]
then
    echo "Please install net-tools first!"
    exit 1
fi

echo "Get nic $eth_name info"
ipaddr=$(ifconfig "$eth_name" | grep " inet " | awk '{print $2}')
netmask=$(ifconfig "$eth_name" | grep " inet " | awk '{print $4}')
gateway=$(ip r | grep "$eth_name" | grep default | awk '{print $3}')
if [ -z "$ipaddr" ] || [ -z "$netmask" ]
then
    echo "Get nic $eth_name info error: ipaddr=$ipaddr,netmask=$netmask"
    exit 1
fi

echo "Backup $eth_name config file"
cp -v /etc/sysconfig/network-scripts/ifcfg-${eth_name} /opt/

echo "Config $br_name and $eth_name config file"
cat > /etc/sysconfig/network-scripts/ifcfg-${eth_name} << EOF
DEVICE=${eth_name}
TYPE=Ethernet
NM_CONTROLLED=no
BOOTPROTO=none
BRIDGE=${br_name}
ONBOOT=yes
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-${br_name} << EOF
DEVICE=${br_name}
TYPE=Bridge
BOOTPROTO=static
IPADDR=${ipaddr}
NETMASK=${netmask}
ONBOOT=yes
EOF

if [ -n "$gateway" ]
then
    echo "GATEWAY=${gateway}" >>/etc/sysconfig/network-scripts/ifcfg-${br_name}
    echo "DEFROUTE=yes" >>/etc/sysconfig/network-scripts/ifcfg-${br_name}
fi

echo "Stop and disable NetworkManager"
systemctl stop NetworkManager
systemctl disable NetworkManager

echo "Restart network"
systemctl restart network

echo "Show bridge"
brctl show

echo "Show network"
ifconfig ${eth_name}
ifconfig ${br_name}

echo "Completed successfully."
