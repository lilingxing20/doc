#!/bin/bash
## by lixx
# 2021-04-08
#

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)

tar_file="rpms/centos1810_kvm_rpms.tar.gz"


if [ ! -f "$SCRIPTS_DIR/$tar_file" ]
then
    echo "Not found: $SCRIPTS_DIR/$tar_file"
    exit 404
fi

sys_version=$(cat /etc/redhat-release | awk '{print $4}')
if [ "$sys_version" != "7.6.1810" ]
then
    echo "The current operating system version is $sys_version"
    echo "Only support operating system CentOS 7.6.1810 environment!"
    exit 1
fi

echo "Unzip offline package"
tar zxf $SCRIPTS_DIR/$tar_file

echo "Backup system yum repo file"
test -d /etc/yum.repos.d/bak01 || mkdir /etc/yum.repos.d/bak01
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak01

echo "Set local yum repo file"
local_repo_file='/etc/yum.repos.d/local.repo'
cat > $local_repo_file <<EOF
[local-kvm-rpms]
name=local-kvm-rpms
baseurl=file://${SCRIPTS_DIR}/centos1810_kvm_rpms/
enabled=1
gpgcheck=0
EOF

echo "Install kvm env rpms"
yum install net-tools libvirt virt-install libguestfs libguestfs-tools -y --enablerepo=local-kvm-rpms

echo "Clean local yum repo file"
test -f $local_repo_file && rm -f $local_repo_file
test -d ${SCRIPTS_DIR}/centos1810_kvm_rpms &&  rm -rf ${SCRIPTS_DIR}/centos1810_kvm_rpms

echo "Restore system yum repo file"
mv /etc/yum.repos.d/bak01/*.repo /etc/yum.repos.d/
test -d /etc/yum.repos.d/bak01 && rmdir /etc/yum.repos.d/bak01

echo "Start libvirtd"
systemctl start libvirtd
systemctl enable libvirtd

virsh list --all

echo "Completed successfully."
