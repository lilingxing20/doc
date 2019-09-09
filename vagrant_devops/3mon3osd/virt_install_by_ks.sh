#!/bin/bash
# created time: 2019-08-28

vm_name='testks'
net_name='vagrant-libvirt'
iso_file='/home/CentOS-7-x86_64-Minimal-1810.iso'
ks_file='ks=http://172.16.134.34/ks/ks.cfg'

virt-install --name=${vm_name} \
--disk /tmp/${vm_name}.qcow2,format=qcow2,bus=virtio,size=10 \
--graphics vnc,listen=0.0.0.0,port=-1,keymap=en_us \
--ram=1024 \
--vcpus=1 \
--arch=x86_64 \
--os-variant=rhel7 \
--os-type=linux \
--network network=${net_name},model=virtio \
--extra-args=${ks_file} \
--location=${iso_file} \
--check all=off
