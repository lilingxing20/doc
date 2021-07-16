#!/bin/bash
## by lixx
# 2021-04-08
#

ssh_dir=/root/.ssh
test -d ${ssh_dir} || mkdir -m 700 ${ssh_dir}
test -f "${ssh_dir}/id_rsa.pub" || ssh-keygen -f ${ssh_dir}/id_rsa -N ""
test -f "${ssh_dir}/authorized_keys" || touch "${ssh_dir}/authorized_keys"
chmod 600 ${ssh_dir}/authorized_keys
